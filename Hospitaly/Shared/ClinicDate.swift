//
//  ClinicDate.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

enum ClinicDate {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        return calendar
    }()

    private static let slotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func dayString(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func date(day: String, time: String) -> Date? {
        slotFormatter.date(from: "\(day) \(time)")
    }

    static func label(_ date: Date, as style: Date.FormatStyle) -> String {
        var style = style
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    static func time(_ date: Date) -> String {
        label(date, as: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute().locale(Locale(identifier: "en_US")))
    }
}
