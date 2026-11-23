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
    @ObservationIgnored private var currentRequest: UUID?

    func loadNextAppointment(using request: @MainActor () async throws -> [Appointment]) async {
        guard !Task.isCancelled else { return }
        let requestID = UUID()
        currentRequest = requestID
        phase = .loading

        do {
            let appointments = try await request()
            try Task.checkCancellation()
            guard requestID == currentRequest else { return }
            let now = Date.now
            let next = appointments
                .filter { $0.isUpcoming && $0.slot.start > now }
                .min { $0.slot.start < $1.slot.start }
            phase = .loaded(next)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, requestID == currentRequest else { return }
            phase = .failed(error.localizedDescription)
        }
    }
}
