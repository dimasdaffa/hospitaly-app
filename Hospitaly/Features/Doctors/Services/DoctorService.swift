//
//  DoctorService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct DoctorService {
    let client: APIClient

    func list(token: String) async throws -> [Doctor] {
        let response: [DoctorResponse] = try await client.get("api/doctors", token: token)
        let now = Date.now

        return response.map { doctor in
            Doctor(
                id: doctor.id.uuidString,
                name: doctor.name,
                specialty: doctor.specialty,
                hospital: nonBlank(doctor.practice?.name) ?? "Practice location unavailable",
                portraitName: nil,
                rating: doctor.rating,
                reviewCount: doctor.reviewCount,
                experienceYears: doctor.experience,
                nextAvailable: slotLabel(doctor.nextAvailable, relativeTo: now),
                license: nonBlank(doctor.license),
                patientCount: doctor.totalPatients,
                bio: nonBlank(doctor.bio),
                practiceLocation: [doctor.practice?.address, doctor.practice?.room]
                    .compactMap { nonBlank($0) }
                    .joined(separator: ", "),
                consultationFee: doctor.practice?.fee,
                avatarURL: nonBlank(doctor.avatarURL).flatMap { client.publicImageURL($0) },
                isFavorite: doctor.isFavorite ?? false,
                usesDemoSchedule: false
            )
        }
    }

    private func slotLabel(_ slot: DoctorResponse.Slot?, relativeTo now: Date) -> String? {
        guard let slot, slot.available,
              let start = ClinicDate.date(day: slot.date, time: slot.time),
              start > now else { return nil }

        let calendar = ClinicDate.calendar
        let day: String
        if calendar.isDate(start, inSameDayAs: now) {
            day = "Today"
        } else if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
                  calendar.isDate(start, inSameDayAs: tomorrow) {
            day = "Tomorrow"
        } else {
            day = ClinicDate.label(start, as: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
        }

        return "\(day), \(ClinicDate.time(start))"
    }

    private func nonBlank(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }
}
