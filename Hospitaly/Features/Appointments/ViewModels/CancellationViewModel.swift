//
//  CancellationViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class CancellationViewModel {
    var reason: CancellationRequest.Reason?
    var note = ""

    private var attempt: CancellationRequest?
    private(set) var isSubmitting = false
    private(set) var appointmentChanged = false
    private(set) var errorMessage: String?

    var hasAttempt: Bool { attempt != nil }
    private var trimmedNote: String { note.trimmingCharacters(in: .whitespacesAndNewlines) }
    var noteIsTooLong: Bool { trimmedNote.utf8.count > 255 }
    var canSubmit: Bool { reason != nil && !noteIsTooLong && !isSubmitting && !appointmentChanged }

    func submit(
        appointment: Appointment,
        using request: @MainActor (Appointment, CancellationRequest) async throws -> Appointment
    ) async -> Appointment? {
        guard canSubmit, let reason else { return nil }
        let body = attempt ?? CancellationRequest(
            reason: reason.rawValue, note: trimmedNote.isEmpty ? nil : trimmedNote
        )
        attempt = body
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            return try await request(appointment, body)
        } catch APIError.httpStatus(let code) where code == 409 || code == 404 {
            appointmentChanged = true
            errorMessage = "This appointment has changed. Return to My Appointments to see its latest status."
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = error.localizedDescription
        }
        return nil
    }
}
