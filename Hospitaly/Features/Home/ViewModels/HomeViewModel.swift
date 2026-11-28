//
//  HomeViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class HomeViewModel {
    enum Phase: Equatable {
        case loading
        case loaded(Appointment?)
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private(set) var isLoading = false
    private(set) var refreshError: String?
    @ObservationIgnored private var currentRequest: UUID?

    func loadNextAppointment(using request: @MainActor () async throws -> [Appointment]) async {
        guard !Task.isCancelled else { return }
        let previous = phase
        let requestID = UUID()
        currentRequest = requestID
        if case .failed = phase { phase = .loading }
        isLoading = true
        defer {
            if currentRequest == requestID {
                currentRequest = nil
                isLoading = false
            }
        }

        do {
            let appointments = try await request()
            try Task.checkCancellation()
            guard currentRequest == requestID else { return }
            let now = Date.now
            let next = appointments
                .filter { $0.isUpcoming && $0.slot.start > now }
                .min { $0.slot.start < $1.slot.start }
            phase = .loaded(next)
            refreshError = nil
        } catch is CancellationError {
            if currentRequest == requestID { phase = previous }
        } catch {
            guard currentRequest == requestID else { return }
            if Task.isCancelled {
                phase = previous
            } else if case .loaded = previous {
                refreshError = error.localizedDescription
            } else {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}
