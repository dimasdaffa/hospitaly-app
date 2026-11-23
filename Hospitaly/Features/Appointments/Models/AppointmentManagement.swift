//
//  AppointmentManagement.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct AppointmentManagement {
    let loadSlots: @MainActor (Appointment, ClosedRange<Date>) async throws -> [AppointmentSlot]
    let reschedule: @MainActor (Appointment, AppointmentSlot) async throws -> Appointment
    let cancel: @MainActor (Appointment, CancellationRequest) async throws -> Appointment
}

extension AppointmentManagement {
    static let preview = AppointmentManagement(
        loadSlots: { _, _ in [AppointmentSlot.sample(dayOffset: 2), .sample(dayOffset: 4)] },
        reschedule: { appointment, slot in
            Appointment(
                id: appointment.id, doctor: appointment.doctor, slot: slot,
                reason: appointment.reason, complaints: appointment.complaints,
                status: .pending, referenceNumber: appointment.referenceNumber
            )
        },
        cancel: { appointment, _ in
            Appointment(
                id: appointment.id, doctor: appointment.doctor, slot: appointment.slot,
                reason: appointment.reason, complaints: appointment.complaints,
                status: .cancellationRequested, referenceNumber: appointment.referenceNumber
            )
        }
    )
}
