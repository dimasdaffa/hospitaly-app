//
//  Appointment.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct Appointment: Identifiable, Hashable, Sendable {
    enum Status: String, Hashable, Sendable {
        case pending, approved, completed, rejected, cancelled, unknown
        case cancellationRequested = "cancellation_requested"

        var title: String {
            switch self {
            case .pending: "Pending Approval"
            case .approved: "Approved"
            case .completed: "Completed"
            case .rejected: "Rejected"
            case .cancelled: "Cancelled"
            case .cancellationRequested: "Cancellation Requested"
            case .unknown: "Status Unavailable"
            }
        }
    }

    let id: UUID
    let doctor: Doctor
    let slot: AppointmentSlot
    let reason: String
    let complaints: String
    let status: Status
    let referenceNumber: String

    init(
        id: UUID = UUID(), doctor: Doctor, slot: AppointmentSlot, reason: String,
        complaints: String, status: Status = .pending, referenceNumber: String? = nil
    ) {
        self.id = id
        self.doctor = doctor
        self.slot = slot
        self.reason = reason
        self.complaints = complaints
        self.status = status
        self.referenceNumber = referenceNumber ?? "REF-\(id.uuidString.prefix(8))"
    }

    var isUpcoming: Bool {
        switch status {
        case .completed, .cancelled, .rejected:
            false
        case .pending, .approved, .cancellationRequested, .unknown:
            slot.end > .now
        }
    }

    static let sample = Appointment(
        doctor: Doctor.samples[0], slot: .sample(), reason: "General checkup", complaints: ""
    )

    static let samples = [
        Appointment(
            doctor: Doctor.samples[2], slot: .sample(dayOffset: 3, hour: 9),
            reason: "General checkup", complaints: "", status: .approved
        ),
        Appointment(
            doctor: Doctor.samples[0], slot: .sample(dayOffset: -3),
            reason: "Follow-up", complaints: "", status: .completed
        )
    ]
}
