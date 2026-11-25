//
//  NotificationSettingsViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation
import Observation

@Observable
final class NotificationSettingsViewModel {
    var appointmentUpdates = false
    private(set) var confirmed: Bool?
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var loadError: String?
    private(set) var saveError: String?
    private(set) var didSave = false

    var canSave: Bool { confirmed != nil && confirmed != appointmentUpdates && !isSaving }

    func load(using request: @MainActor () async throws -> AppointmentNotificationSettings) async {
        guard !isSaving, !isLoading, !Task.isCancelled else { return }
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        do {
            let result = try await request()
            try Task.checkCancellation()
            confirmed = result.appointmentUpdates
            appointmentUpdates = result.appointmentUpdates
        } catch where !Task.isCancelled && !(error is CancellationError) {
            loadError = error.localizedDescription
        } catch {
            return
        }
    }

    func save(
        using request: @MainActor (AppointmentNotificationSettings) async throws -> AppointmentNotificationSettings
    ) async {
        guard canSave, !Task.isCancelled else { return }
        isSaving = true
        saveError = nil
        didSave = false
        defer { isSaving = false }

        do {
            let settings = AppointmentNotificationSettings(appointmentUpdates: appointmentUpdates)
            let saved = try await request(settings)
            confirmed = saved.appointmentUpdates
            appointmentUpdates = saved.appointmentUpdates
            didSave = true
        } catch where !Task.isCancelled && !(error is CancellationError) {
            saveError = error.localizedDescription
        } catch {
            return
        }
    }
}
