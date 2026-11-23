//
//  HealthTrackerActions.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct HealthTrackerActions {
    let load: @MainActor (HealthMetric, ClosedRange<Date>) async throws -> [HealthReading]
    let save: @MainActor (HealthReadingRequest) async throws -> HealthReading
}

extension HealthTrackerActions {
    static let preview = HealthTrackerActions(
        load: { _, _ in HealthReading.samples },
        save: { request in
            HealthReading(
                id: UUID(), date: request.date, measuredAt: .now, createdAt: nil,
                weight: request.weight, heartRate: request.heartRate, bloodPressure: request.bloodPressure
            )
        }
    )
}
