//
//  HealthService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct HealthService {
    let client: APIClient

    func list(metric: HealthMetric, from: Date, to: Date, token: String) async throws -> [HealthReading] {
        try await client.get("api/health-updates", token: token, query: [
            URLQueryItem(name: "metric", value: metric.rawValue),
            URLQueryItem(name: "from", value: ClinicDate.dayString(from)),
            URLQueryItem(name: "to", value: ClinicDate.dayString(to))
        ])
    }

    func log(_ request: HealthReadingRequest, token: String) async throws -> HealthReading {
        try await client.post("api/health-updates", body: request, token: token)
    }
}
