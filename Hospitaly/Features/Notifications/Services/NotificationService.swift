//
//  NotificationService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct NotificationService {
    let client: APIClient

    func list(token: String) async throws -> [PatientNotification] {
        try await client.get("api/notifications", token: token)
    }

    func markRead(id: UUID, token: String) async throws {
        try await client.put("api/notifications/\(id.uuidString)/read", token: token)
    }
}
