//
//  AppointmentSlot.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct AppointmentSlot: Identifiable, Hashable, Sendable {
    let start: Date
    let end: Date
    let isAvailable: Bool

    var id: Date { start }

    var isMorning: Bool {
        ClinicDate.calendar.component(.hour, from: start) < 12
    }

    var timeLabel: String {
        ClinicDate.time(start)
    }

    var dateLabel: String {
        ClinicDate.label(start, as: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    static func sample(dayOffset: Int = 1, hour: Int = 10) -> AppointmentSlot {
        let calendar = ClinicDate.calendar
        let today = calendar.startOfDay(for: .now)
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
        let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        return AppointmentSlot(start: start, end: start.addingTimeInterval(1_800), isAvailable: true)
    }
}
