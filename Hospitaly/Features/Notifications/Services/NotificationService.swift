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

    func settings(token: String) async throws -> AppointmentNotificationSettings {
        try await client.get("api/users/me/notification-settings", token: token)
    }

    func updateSettings(
        _ settings: AppointmentNotificationSettings, token: String
    ) async throws -> AppointmentNotificationSettings {
        try await client.put("api/users/me/notification-settings", body: settings, token: token)
    }
}
