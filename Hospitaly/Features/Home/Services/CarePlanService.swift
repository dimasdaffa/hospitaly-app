//
//  CarePlanService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct CarePlanService {
    private struct TakenRequest: Encodable {
        let date: String
        let time: String
    }

    let client: APIClient

    func list(date: String, token: String) async throws -> [CarePlanEntry] {
        try await client.get(
            "api/care-plan", token: token, query: [URLQueryItem(name: "date", value: date)]
        )
    }

    func markTaken(_ entry: CarePlanEntry, token: String) async throws -> CarePlanEntry {
        let response: CarePlanEntry = try await client.put(
            "api/care-plan/\(entry.recordId.uuidString)/\(entry.medication.id.uuidString)/taken",
            body: TakenRequest(date: entry.date, time: entry.time), token: token
        )
        guard response.id == entry.id, response.takenAt != nil else { throw APIError.invalidPayload }
        return response
    }
}
