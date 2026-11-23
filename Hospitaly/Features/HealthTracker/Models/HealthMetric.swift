//
//  HealthMetric.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

enum HealthMetric: String, CaseIterable, Identifiable {
    case bloodPressure, weight, heartRate

    var id: Self { self }

    var title: String {
        switch self {
        case .bloodPressure: "Blood Pressure"
        case .weight: "Weight"
        case .heartRate: "Heart Rate"
        }
    }

    var unit: String {
        switch self {
        case .bloodPressure: "mmHg"
        case .weight: "kg"
        case .heartRate: "bpm"
        }
    }

    var symbol: String {
        switch self {
        case .bloodPressure: "waveform.path.ecg"
        case .weight: "scalemass"
        case .heartRate: "heart.fill"
        }
    }

    func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...(self == .weight ? 1 : 0))))
    }

    func format(primary: Double, secondary: Double? = nil) -> String {
        let value = secondary.map { "\(format(primary))/\(format($0))" } ?? format(primary)
        return "\(value) \(unit)"
    }
}
