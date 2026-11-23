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

    static func label(_ date: Date, as style: Date.FormatStyle) -> String {
        var style = style
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    static func time(_ date: Date) -> String {
        label(date, as: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute().locale(Locale(identifier: "en_US")))
    }
}
