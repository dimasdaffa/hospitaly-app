//
//  NotificationsViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class NotificationsViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var notifications: [PatientNotification] = []
    private(set) var phase: Phase = .idle
    private(set) var markingReadID: UUID?
    private(set) var readError: String?

    var hasUnread: Bool {
        notifications.contains(where: \.isUnread)
    }

    func load(using request: @MainActor () async throws -> [PatientNotification]) async {
        guard phase != .loading, markingReadID == nil, !Task.isCancelled else { return }
        let previous = phase
        phase = .loading
        readError = nil
        do {
            let result = try await request()
            try Task.checkCancellation()
            notifications = result
            phase = .loaded
        } catch is CancellationError {
            phase = previous
        } catch {
            phase = Task.isCancelled ? previous : .failed(error.localizedDescription)
        }
    }

    func markRead(_ id: UUID, using request: @MainActor (UUID) async throws -> Void) async {
        guard phase != .loading, markingReadID == nil, !Task.isCancelled,
              let index = notifications.firstIndex(where: { $0.id == id && $0.isUnread }) else { return }
        markingReadID = id
        readError = nil
        defer { markingReadID = nil }

        do {
            try await request(id)
            notifications[index].readAt = .now
        } catch is CancellationError {
            return
        } catch {
            readError = error.localizedDescription
        }
    }
}
