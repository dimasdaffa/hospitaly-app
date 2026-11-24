//
//  ConversationViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation
import Observation

@Observable
final class ConversationViewModel {
    private enum Load: Equatable {
        case latest, earlier
    }

    let peer: MessagePeer
    let patientID: UUID
    private(set) var messages: [Message] = []
    private(set) var hasLoaded = false
    private(set) var hasEarlier = false
    private(set) var loadError: String?
    private(set) var earlierError: String?
    private(set) var readError: String?
    private(set) var sendError: String?
    private(set) var isSending = false
    private(set) var isMarkingRead = false
    private var loading: Load?
    private var nextPage = 2
    private var unconfirmed: (content: String, knownIDs: Set<UUID>)?
    var draft = ""

    init(peer: MessagePeer, patientID: UUID) {
        self.peer = peer
        self.patientID = patientID
    }

    var isLoading: Bool { loading != nil }
    var isLoadingEarlier: Bool { loading == .earlier }
    var needsHistoryCheck: Bool { unconfirmed != nil }
    var characterCount: Int { draft.trimmingCharacters(in: .whitespacesAndNewlines).count }

    var canSend: Bool {
        hasLoaded && !isSending && loading == nil && unconfirmed == nil &&
            (1...MessageService.characterLimit).contains(characterCount)
    }

    func loadLatest(using actions: MessageActions, onChange: @MainActor () async -> Void) async {
        guard loading == nil, !isSending, !isMarkingRead, !Task.isCancelled else { return }
        loading = .latest
        loadError = nil
        do {
            defer { loading = nil }
            let rows = try await actions.loadMessages(peer.id, 1)
            try Task.checkCancellation()
            try validateThread(rows)
            messages = rows
            hasLoaded = true
            nextPage = 2
            hasEarlier = rows.count == MessageService.pageSize
            earlierError = nil
            resolveUnconfirmedSend(in: rows)
        } catch where !Task.isCancelled && !(error is CancellationError) {
            loadError = error.localizedDescription
            return
        } catch {
            return
        }
        await markUnread(using: actions, onChange: onChange)
    }

    func loadEarlier(using actions: MessageActions, onChange: @MainActor () async -> Void) async -> Bool {
        guard hasEarlier, loading == nil, !isSending, !isMarkingRead, !Task.isCancelled else { return false }
        loading = .earlier
        earlierError = nil
        let inserted: Bool
        do {
            defer { loading = nil }
            let rows = try await actions.loadMessages(peer.id, nextPage)
            try Task.checkCancellation()
            try validateThread(rows)
            let known = Set(messages.map(\.id))
            let earlier = rows.filter { !known.contains($0.id) }
            messages.insert(contentsOf: earlier, at: 0)
            hasEarlier = rows.count == MessageService.pageSize && nextPage < MessageService.lastPage
            nextPage += 1
            inserted = !earlier.isEmpty
        } catch where !Task.isCancelled && !(error is CancellationError) {
            earlierError = error.localizedDescription
            return false
        } catch {
            return false
        }
        await markUnread(using: actions, onChange: onChange)
        return inserted
    }

    func send(using actions: MessageActions, onChange: @MainActor () async -> Void) async {
        guard canSend, !Task.isCancelled else { return }
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let knownIDs = Set(messages.map(\.id))
        isSending = true
        sendError = nil
        let didSend: Bool
        do {
            defer { isSending = false }
            let sent = try await actions.send(peer.id, content)
            guard sent.senderId == patientID, sent.receiverId == peer.id else {
                throw APIError.invalidPayload
            }
            if !knownIDs.contains(sent.id) { messages.append(sent) }
            draft = ""
            didSend = true
        } catch APIError.httpStatus(let status) where [400, 401, 403, 404].contains(status) {
            sendError = APIError.httpStatus(status).localizedDescription
            didSend = false
        } catch {
            // shortcut: Vapor has no replay key for messages. Check the latest page before offering another send.
            unconfirmed = (content, knownIDs)
            sendError = "Delivery couldn’t be confirmed. Check the conversation before sending again."
            didSend = false
        }
        if didSend { await onChange() }
    }

    func markUnread(using actions: MessageActions, onChange: @MainActor () async -> Void) async {
        guard !isMarkingRead, !Task.isCancelled else { return }
        isMarkingRead = true
        readError = nil
        defer { isMarkingRead = false }

        let unread = messages.filter { $0.senderId == peer.id && $0.receiverId == patientID && !$0.isRead }
        var changed = false
        for message in unread {
            guard !Task.isCancelled else { break }
            do {
                try await actions.markRead(message.id)
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].isRead = true
                }
                changed = true
            } catch APIError.httpStatus(401) {
                break
            } catch where !Task.isCancelled && !(error is CancellationError) {
                readError = "Couldn’t mark some messages as read."
            } catch {
                break
            }
        }

        if changed, !Task.isCancelled { await onChange() }
    }

    private func resolveUnconfirmedSend(in rows: [Message]) {
        guard let unconfirmed else { return }
        let found = rows.contains { row in
            row.senderId == patientID && row.content == unconfirmed.content && !unconfirmed.knownIDs.contains(row.id)
        }
        if found { draft = "" }
        sendError = found ? nil : "Delivery is still unconfirmed. Review the conversation before sending again."
        self.unconfirmed = nil
    }

    private func validateThread(_ rows: [Message]) throws {
        guard rows.allSatisfy({ message in
            (message.senderId == patientID && message.receiverId == peer.id) ||
                (message.senderId == peer.id && message.receiverId == patientID)
        }) else { throw APIError.invalidPayload }
    }
}
