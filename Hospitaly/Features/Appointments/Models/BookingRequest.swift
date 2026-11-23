//
//  BookingRequest.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct BookingRequest: Encodable, Sendable {
    let doctorId: String
    let date: String
    let time: String
    let reason: String
    let complaints: String?
    let idempotencyKey = UUID()

    enum CodingKeys: String, CodingKey {
        case doctorId, date, time, reason, complaints
    }

    init(doctor: Doctor, slot: AppointmentSlot, reason: String, complaints: String?) {
        doctorId = doctor.id
        date = ClinicDate.dayString(slot.start)
        time = ClinicDate.clockString(slot.start)
        self.reason = reason
        self.complaints = complaints
    }
}
