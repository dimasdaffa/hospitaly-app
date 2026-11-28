//
//  ProfileSettingsActions.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

struct ProfileSettingsActions {
    let updateProfile: @MainActor (ProfileUpdateRequest) async throws -> Void
    let uploadPhoto: @MainActor (Data) async throws -> String
    let changePassword: @MainActor (ChangePasswordRequest) async throws -> Void
    let loadNotificationSettings: @MainActor () async throws -> AppointmentNotificationSettings
    let saveNotificationSettings: @MainActor (AppointmentNotificationSettings) async throws -> AppointmentNotificationSettings
}

extension ProfileSettingsActions {
    static var preview: Self {
        var preferences = AppointmentNotificationSettings(appointmentUpdates: true)
        return Self(
            updateProfile: { _ in },
            uploadPhoto: { _ in "/uploads/preview.jpg" },
            changePassword: { _ in },
            loadNotificationSettings: { preferences },
            saveNotificationSettings: { preferences = $0; return $0 }
        )
    }
}
