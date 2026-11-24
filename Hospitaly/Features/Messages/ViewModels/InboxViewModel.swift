//
//  InboxViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation
import Observation

@Observable
final class InboxViewModel {
    enum Phase: Equatable {
        case loading, loaded, failed(String)
    }

    private(set) var conversations: [Conversation] = []
    private(set) var phase = Phase.loading
    private(set) var searchResults: [Conversation] = []
    private(set) var searchPhase = Phase.loading
    private(set) var resultQuery = ""
    @ObservationIgnored private var inboxRequestID: UUID?
    @ObservationIgnored private var searchRequestID: UUID?
    var query = ""

    var searchTerm: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    var hasUnread: Bool { conversations.contains { $0.unreadCount > 0 } }

    func load(using request: @MainActor (String) async throws -> [Conversation]) async {
        guard !Task.isCancelled else { return }
        let id = UUID()
        inboxRequestID = id
        if conversations.isEmpty { phase = .loading }

        do {
            let rows = try await request("")
            try Task.checkCancellation()
            guard id == inboxRequestID else { return }
            conversations = rows
            phase = .loaded
        } catch where !Task.isCancelled && !(error is CancellationError) {
            guard id == inboxRequestID else { return }
            phase = .failed(error.localizedDescription)
        } catch {
            return
        }
    }

    func search(using request: @MainActor (String) async throws -> [Conversation]) async {
        let term = searchTerm
        guard !term.isEmpty, !Task.isCancelled else { return }
        let id = UUID()
        searchRequestID = id
        resultQuery = term
        searchResults = []
        searchPhase = .loading

        do {
            try await Task.sleep(for: .milliseconds(300))
            let rows = try await request(term)
            try Task.checkCancellation()
            guard term == searchTerm, id == searchRequestID else { return }
            searchResults = rows
            searchPhase = .loaded
        } catch where !Task.isCancelled && !(error is CancellationError) {
            guard term == searchTerm, id == searchRequestID else { return }
            searchPhase = .failed(error.localizedDescription)
        } catch {
            return
        }
    }
}
