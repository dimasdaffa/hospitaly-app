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
                LoadingStateView("Loading settings…")
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

        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $model.appointmentUpdates) {
                        Label {
                            Text("Appointment Updates")
                                .font(.headline)
                                .foregroundStyle(Color.themeText)
                        } icon: {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(Color.themeCrimsonInk)
                                .frame(width: 40, height: 40)
                                .background(Color.themeGlassRose, in: .rect(cornerRadius: 12))
                        }
                    }
                    .tint(Color.themePrimary)

                    Text("Receive updates in the app when the hospital reviews your appointments.")
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                }
                .padding(16)
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))

                if let error = model.saveError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color.themeCrimsonInk)
                } else if model.didSave && !model.canSave {
                    Label("Preferences saved.", systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.themeAvailableText)
                }
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .environment(\.colorScheme, .light)
        .disabled(model.isSaving)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: model.isSaving ? "Saving…" : "Save Preferences", isLoading: model.isSaving) {
                Task { await model.save(using: saveSettings) }
            }
            .disabled(!model.canSave)
            .frame(maxWidth: Theme.dashboardWidth)
            .padding(.horizontal, Theme.contentInset)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
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
