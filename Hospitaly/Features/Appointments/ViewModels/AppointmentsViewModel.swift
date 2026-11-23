//
//  AppointmentsViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class AppointmentsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var appointments: [Appointment]
    private(set) var phase: Phase
    private(set) var loadAttempt = 0

    init(appointments: [Appointment], loadsFromAPI: Bool) {
        self.appointments = appointments
        phase = loadsFromAPI ? .loading : .loaded
    }

    func reload() {
        guard phase != .loading else { return }
        phase = .loading
        loadAttempt += 1
    }

    func load(using request: @MainActor () async throws -> [Appointment]) async {
        guard phase == .loading, !Task.isCancelled else { return }
        let attempt = loadAttempt
        do {
            let result = try await request()
            try Task.checkCancellation()
            guard attempt == loadAttempt else { return }
            appointments = result
            phase = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, attempt == loadAttempt else { return }
            phase = .failed(error.localizedDescription)
        }
    }

    func apply(_ appointment: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == appointment.id }) {
            appointments[index] = appointment
        } else {
            appointments.append(appointment)
        }

        if phase == .loading {
            loadAttempt += 1
        }
    }
}
