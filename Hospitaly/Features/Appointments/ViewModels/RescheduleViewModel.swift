//
//  RescheduleViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class RescheduleViewModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }

    let appointment: Appointment
    let days: [Date]
    let dateRange: ClosedRange<Date>
    var selectedDate: Date {
        didSet {
            if !ClinicDate.calendar.isDate(selectedDate, inSameDayAs: oldValue) {
                selectedSlot = nil
            }
        }
    }

    private(set) var phase: Phase = .loading
    private(set) var loadAttempt = 0
    private(set) var selectedSlot: AppointmentSlot?
    private(set) var isSubmitting = false
    private(set) var submissionError: String?
    private var slots: [AppointmentSlot] = []

    init(appointment: Appointment) {
        self.appointment = appointment
        let calendar = ClinicDate.calendar
        let today = calendar.startOfDay(for: .now)
        let days = (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        self.days = days
        dateRange = today...(days.last ?? today)
        selectedDate = today
    }

    var hasAvailableSlots: Bool { slots.contains(where: \.isAvailable) }

    var slotsForSelectedDate: [AppointmentSlot] {
        slots.filter { ClinicDate.calendar.isDate($0.start, inSameDayAs: selectedDate) }
    }

    func selectSlot(_ slot: AppointmentSlot) {
        guard !isSubmitting, slot.isAvailable, slot.start > .now, slotsForSelectedDate.contains(slot) else { return }
        selectedSlot = slot
        submissionError = nil
    }

    func reload() {
        guard phase != .loading else { return }
        phase = .loading
        selectedSlot = nil
        loadAttempt += 1
    }

    func load(using request: @MainActor (Appointment, ClosedRange<Date>) async throws -> [AppointmentSlot]) async {
        guard phase == .loading, !Task.isCancelled else { return }
        do {
            let result = try await request(appointment, dateRange)
            try Task.checkCancellation()
            slots = result.filter { $0.start != appointment.slot.start }
            if let first = slots.first(where: \.isAvailable) {
                selectedDate = ClinicDate.calendar.startOfDay(for: first.start)
            }
            phase = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failed(error.localizedDescription)
        }
    }

    func submit(using request: @MainActor (Appointment, AppointmentSlot) async throws -> Appointment) async -> Appointment? {
        guard !isSubmitting, phase == .loaded, let slot = selectedSlot else { return nil }
        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }

        do {
            return try await request(appointment, slot)
        } catch APIError.httpStatus(let code) where code == 409 || code == 422 || (code == 400 && slot.start <= .now) {
            submissionError = "The appointment or selected time changed. Check the available times again."
            reload()
        } catch is CancellationError {
            return nil
        } catch {
            submissionError = error.localizedDescription
        }
        return nil
    }
}
