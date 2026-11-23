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
            let next = doctor.nextAvailable.flatMap { slot -> String? in
                guard slot.available, let start = ClinicDate.date(day: slot.date, time: slot.time),
                      start > now else { return nil }
                return slotLabel(start, relativeTo: now)
            }
            return displayDoctor(doctor, nextAvailable: next)
        }
    }

    func details(id: String, range: ClosedRange<Date>, token: String) async throws -> DoctorDetailData {
        guard let doctorID = UUID(uuidString: id) else { throw APIError.invalidPayload }
        let path = "api/doctors/\(doctorID.uuidString)"

        async let profileRequest: DoctorResponse = client.get(path, token: token)
        async let slotsRequest: [AppointmentSlot] = availability(id: id, range: range, token: token)
        async let hoursRequest: [DoctorDetailData.WeeklyHours] = client.get(
            "api/schedules", token: token, query: [URLQueryItem(name: "doctorId", value: doctorID.uuidString)]
        )

        let (profile, slots, hours) = try await (profileRequest, slotsRequest, hoursRequest)
        let now = Date.now
        let next = slots.first(where: \.isAvailable).map { slotLabel($0.start, relativeTo: now) }
        return DoctorDetailData(
            doctor: displayDoctor(profile, nextAvailable: next),
            slots: slots,
            weeklyHours: hours.sorted {
                ($0.dayOrder, $0.startTime) < ($1.dayOrder, $1.startTime)
            }
        )
    }

    func availability(id: String, range: ClosedRange<Date>, token: String) async throws -> [AppointmentSlot] {
        guard let doctorID = UUID(uuidString: id) else { throw APIError.invalidPayload }
        let query = [
            URLQueryItem(name: "from", value: ClinicDate.dayString(range.lowerBound)),
            URLQueryItem(name: "to", value: ClinicDate.dayString(range.upperBound))
        ]
        let slotRows: [DoctorResponse.Slot] = try await client.get(
            "api/doctors/\(doctorID.uuidString)/availability", token: token, query: query
        )
        let now = Date.now
        return try slotRows.map { row in
            guard let start = ClinicDate.date(day: row.date, time: row.time),
                  let end = ClinicDate.date(day: row.date, time: row.endTime),
                  end > start else { throw APIError.invalidPayload }
            return AppointmentSlot(start: start, end: end, isAvailable: row.available && start > now)
        }.sorted { $0.start < $1.start }
    }

    func displayDoctor(_ doctor: DoctorResponse, nextAvailable: String? = nil) -> Doctor {
        Doctor(
            id: doctor.id.uuidString,
            name: doctor.name,
            specialty: doctor.specialty,
            hospital: nonBlank(doctor.practice?.name) ?? "Practice location unavailable",
            portraitName: nil,
            rating: doctor.rating,
            reviewCount: doctor.reviewCount,
            experienceYears: doctor.experience,
            nextAvailable: nextAvailable,
            license: nonBlank(doctor.license),
            patientCount: doctor.totalPatients,
            bio: nonBlank(doctor.bio),
            practiceLocation: [doctor.practice?.address, doctor.practice?.room]
                .compactMap { nonBlank($0) }
                .joined(separator: ", "),
            consultationFee: doctor.practice?.fee,
            avatarURL: nonBlank(doctor.avatarURL).flatMap { client.publicImageURL($0) },
            isFavorite: doctor.isFavorite ?? false,
            usesDemoSchedule: false,
            consultationCurrency: nonBlank(doctor.practice?.currency)?.uppercased()
        )
    }

    private func slotLabel(_ start: Date, relativeTo now: Date) -> String {
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
