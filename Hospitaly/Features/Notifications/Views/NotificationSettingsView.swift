//
//  NotificationSettingsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct NotificationSettingsView: View {
    @State private var model = NotificationSettingsViewModel()
    @State private var loadAttempt = 0

    let loadSettings: @MainActor () async throws -> AppointmentNotificationSettings
    let saveSettings: @MainActor (AppointmentNotificationSettings) async throws -> AppointmentNotificationSettings

    var body: some View {
        Group {
            if model.confirmed != nil {
                settingsForm
            } else if let message = model.loadError {
                ContentUnavailableView {
                    Label("Couldn’t Load Notification Settings", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { loadAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView("Loading settings…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isSaving)
        .task(id: loadAttempt) { await model.load(using: loadSettings) }
    }

    private var settingsForm: some View {
        @Bindable var model = model

        return Form {
            Section {
                Toggle(isOn: $model.appointmentUpdates) {
                    Label("Appointment Updates", systemImage: "bell.badge")
                }
                .tint(Color.themePrimary)
            } footer: {
                Text("Receive updates in the app when the hospital reviews your appointments.")
            }

            if let error = model.saveError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.themePrimary)
            } else if model.didSave && !model.canSave {
                Label("Preferences saved.", systemImage: "checkmark.circle")
                    .foregroundStyle(Color.themeAvailableText)
            }
        }
        .scrollContentBackground(.hidden)
        .environment(\.colorScheme, .light)
        .disabled(model.isSaving)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: model.isSaving ? "Saving…" : "Save Preferences") {
                Task { await model.save(using: saveSettings) }
            }
            .disabled(!model.canSave)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .hospitalyActionBar()
        }
    }
}

#Preview("Appointment Notifications") {
    let actions = ProfileSettingsActions.preview
    NavigationStack {
        NotificationSettingsView(loadSettings: actions.loadNotificationSettings, saveSettings: actions.saveNotificationSettings)
    }
}

#Preview("Load Error") {
    NavigationStack {
        NotificationSettingsView(
            loadSettings: { throw APIError.connectionFailed }, saveSettings: { $0 }
        )
    }
}
