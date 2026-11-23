//
//  HealthReadingRequest.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct HealthReadingRequest: Encodable {
    let date: String
    let measuredAt: String
    let weight: Double?
    let heartRate: Int?
    let bloodPressure: String?

    init(
        measuredAt: Date = .now, weight: Double? = nil,
        heartRate: Int? = nil, bloodPressure: String? = nil
    ) {
        date = ClinicDate.dayString(measuredAt)
        self.measuredAt = measuredAt.ISO8601Format()
        self.weight = weight
        self.heartRate = heartRate
        self.bloodPressure = bloodPressure
    }
}
