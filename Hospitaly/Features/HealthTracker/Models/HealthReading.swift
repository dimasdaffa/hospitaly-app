//
//  HealthReading.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct HealthReading: Decodable, Identifiable, Equatable {
    struct Measurement {
        let primary: Double
        var secondary: Double? = nil
    }

    let id: UUID
    let date: String
    let measuredAt: Date?
    let createdAt: Date?
    let weight: Double?
    let heartRate: Int?
    let bloodPressure: String?

    var recordedAt: Date? { measuredAt ?? createdAt }
    var chartDate: Date? { recordedAt ?? ClinicDate.date(day: date, time: "00:00") }

    var dateLabel: String {
        if let recordedAt {
            return ClinicDate.label(recordedAt, as: .dateTime.month(.abbreviated).day().hour().minute())
        }
        if let chartDate {
            return ClinicDate.label(chartDate, as: .dateTime.month(.abbreviated).day().year())
        }
        return date
    }

    func measurement(for metric: HealthMetric) -> Measurement? {
        switch metric {
        case .bloodPressure:
            let values = bloodPressure?.split(separator: "/", omittingEmptySubsequences: false)
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) } ?? []
            guard values.count == 2, values.allSatisfy({ $0 > 0 }) else { return nil }
            return Measurement(primary: Double(values[0]), secondary: Double(values[1]))
        case .weight:
            guard let weight, weight.isFinite, weight > 0 else { return nil }
            return Measurement(primary: weight)
        case .heartRate:
            guard let heartRate, heartRate > 0 else { return nil }
            return Measurement(primary: Double(heartRate))
        }
    }

    static let samples: [HealthReading] = (0..<4).map { index in
        let date = Date.now.addingTimeInterval(Double(-index) * 86_400)
        return HealthReading(
            id: UUID(), date: ClinicDate.dayString(date), measuredAt: date, createdAt: nil,
            weight: 72.1 + Double(index) * 0.3, heartRate: 72 + index * 2,
            bloodPressure: "\(120 + index * 2)/\(80 + index)"
        )
    }
}
