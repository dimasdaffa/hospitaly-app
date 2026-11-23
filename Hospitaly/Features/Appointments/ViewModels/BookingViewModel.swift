//
//  BookingViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class BookingViewModel {
    var reason = ""
    var complaints = ""

    private(set) var isSubmitting = false
    private(set) var slotUnavailable = false
    private(set) var errorMessage: String?
    // shortcut: Retry survives in this form. Persist securely if retries need to survive relaunch.
    private var attempt: BookingRequest?

    var hasAttempt: Bool { attempt != nil }

    private var trimmedReason: String { reason.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedComplaints: String { complaints.trimmingCharacters(in: .whitespacesAndNewlines) }

    var exceedsLengthLimit: Bool {
        trimmedReason.utf8.count > 255 || trimmedComplaints.utf8.count > 255
    }

    var canSubmit: Bool {
        !isSubmitting && !slotUnavailable && (hasAttempt || (!trimmedReason.isEmpty && !exceedsLengthLimit))
    }

    func submit(
        doctor: Doctor, slot: AppointmentSlot,
        using request: @MainActor (BookingRequest) async throws -> Appointment
    ) async -> Appointment? {
        guard canSubmit else { return nil }
        if attempt == nil && (!slot.isAvailable || slot.start <= .now) {
            slotUnavailable = true
            return nil
        }

        // Keep the same payload and key when a request may have reached the server.
        let booking = attempt ?? BookingRequest(
            doctor: doctor, slot: slot, reason: trimmedReason,
            complaints: trimmedComplaints.isEmpty ? nil : trimmedComplaints
        )
        attempt = booking
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            return try await request(booking)
        } catch APIError.httpStatus(let code)
            where code == 409 || code == 422 || (code == 400 && slot.start <= .now) {
            slotUnavailable = true
            attempt = nil
        } catch is CancellationError {
            return nil
        } catch {
            errorMessage = error.localizedDescription
        }
        return nil
    }
}
