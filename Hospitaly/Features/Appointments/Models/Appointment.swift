//
//  Appointment.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct Appointment: Identifiable, Hashable, Sendable {
    enum Status: String, Hashable, Sendable {
        case pending = "Pending"
        case approved = "Approved"
        case completed = "Completed"
    }

    let id = UUID()
    let doctor: Doctor
    let slot: AppointmentSlot
    let reason: String
    let complaints: String
    var status: Status = .pending

    var referenceNumber: String {
        "REF-\(id.uuidString.prefix(8))"
    }

    var isUpcoming: Bool {
        status != .completed && slot.end > .now
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
