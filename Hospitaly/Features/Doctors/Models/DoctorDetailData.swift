//
//  DoctorDetailData.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct DoctorDetailData: Sendable {
    struct WeeklyHours: Decodable, Identifiable, Sendable {
        let id: UUID
        let dayOfWeek: String
        let startTime: String
        let endTime: String
        let isAvailable: Bool

        private static let weekdays = [
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
        ]

        var dayOrder: Int {
            Self.weekdays.firstIndex(of: dayOfWeek.lowercased()) ?? Self.weekdays.count
        }
    }

    let doctor: Doctor
    let slots: [AppointmentSlot]
    let weeklyHours: [WeeklyHours]
}
