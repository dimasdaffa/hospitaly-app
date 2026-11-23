//
//  AppointmentService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct AppointmentService {
    let client: APIClient

    func book(_ booking: BookingRequest, doctor: Doctor, token: String) async throws -> Appointment {
        guard let doctorID = UUID(uuidString: booking.doctorId) else { throw APIError.invalidPayload }
        let response: AppointmentResponse = try await client.post(
            "api/appointments", body: booking, token: token, idempotencyKey: booking.idempotencyKey
        )
        guard response.doctorId == doctorID else {
            throw APIError.invalidPayload
        }
        return try appointment(from: response, fallbackDoctor: doctor)
    }

    func list(token: String) async throws -> [Appointment] {
        let response: [AppointmentResponse] = try await client.get("api/appointments", token: token)
        return try response.map { try appointment(from: $0) }
    }

    private func appointment(from response: AppointmentResponse, fallbackDoctor: Doctor? = nil) throws -> Appointment {
        guard let start = ClinicDate.date(day: response.date, time: response.time) else {
            throw APIError.invalidPayload
        }

        let end: Date
        if let time = response.endTime, time != "24:00" {
            guard let parsed = ClinicDate.date(day: response.date, time: time), parsed > start else {
                throw APIError.invalidPayload
            }
            end = parsed
        } else {
            // Older appointments can omit endTime. Vapor uses 30-minute appointments.
            end = start.addingTimeInterval(1_800)
        }

        let doctor = response.doctor.map { DoctorService(client: client).displayDoctor($0) }
            ?? fallbackDoctor
            ?? Doctor(
                id: response.doctorId.uuidString,
                name: "Doctor unavailable",
                specialty: "",
                hospital: "Practice location unavailable",
                rating: 0,
                reviewCount: nil,
                experienceYears: 0,
                nextAvailable: nil,
                license: nil,
                patientCount: 0,
                bio: nil,
                practiceLocation: "",
                consultationFee: nil,
                usesDemoSchedule: false
            )

        return Appointment(
            id: response.id,
            doctor: doctor,
            slot: AppointmentSlot(start: start, end: end, isAvailable: false),
            reason: response.reason,
            complaints: response.complaints ?? "",
            status: Appointment.Status(rawValue: response.status) ?? .unknown,
            referenceNumber: response.referenceNumber
        )
    }
}
