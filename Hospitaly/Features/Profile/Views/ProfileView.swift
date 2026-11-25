//
//  ProfileView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct ProfileView: View {
    enum Route: Hashable {
        case personal, documents, security, notifications, help

        var title: String {
            switch self {
            case .personal: "Personal Information"
            case .documents: "Documents & BPJS"
            case .security: "Security"
            case .notifications: "Notifications"
            case .help: "Help Center"
            }
        }

        var subtitle: String? {
            switch self {
            case .personal: "Manage your biodata"
            case .documents: "Insurance and patient documents"
            case .security: "Change your password"
            case .notifications: "Appointment alerts and updates"
            case .help: nil
            }
        }

        var icon: String {
            switch self {
            case .personal: "person.fill"
            case .documents: "doc.text.fill"
            case .security: "lock.fill"
            case .notifications: "bell.fill"
            case .help: "questionmark.circle"
            }
        }
    }

    @State private var signOutError: String?

    let profile: UserProfile
    let onSignOut: @MainActor () throws -> Void
    var avatarURL: URL?
    var settings: ProfileSettingsActions?
    var documents: DocumentsActions?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                identity

                if settings != nil || documents != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        heading("Account Management")
                        if settings != nil { routeLink(.personal) }
                        if documents != nil { routeLink(.documents) }
                        if settings != nil {
                            routeLink(.security)
                            routeLink(.notifications)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    heading("Other")
                    if settings != nil { routeLink(.help) }
                    Button(role: .destructive, action: signOut) {
                        row("Log Out", symbol: "rectangle.portrait.and.arrow.right", accent: .themePrimary,
                            titleColor: .themePrimary)
                    }
                    .buttonStyle(.plain)

                    if let signOutError {
                        Text(signOutError)
                            .font(.footnote)
                            .foregroundStyle(Color.themePrimary)
                    }
                }
            }
            .frame(maxWidth: 440)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Profile Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Route.self, destination: destination)
    }

    private var identity: some View {
        VStack(spacing: 8) {
            if settings != nil {
                NavigationLink(value: Route.personal) {
                    ProfileAvatar(url: avatarURL)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.themeSurface)
                                .frame(width: 28, height: 28)
                                .background(Color.themePrimary, in: .circle)
                                .overlay { Circle().strokeBorder(Color.themeSurface, lineWidth: 2) }
                        }
                }
                .buttonStyle(.plain)
            } else {
                ProfileAvatar(url: avatarURL)
            }

            Text(profile.name)
                .font(.title2.bold())
                .foregroundStyle(Color.themeText)

            if let patientNumber = profile.patientNumber {
                Text("Patient ID #\(patientNumber)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.themeSecondaryText)
            }

            Text(profile.email)
                .font(.footnote)
                .foregroundStyle(Color.themeSecondaryText)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func heading(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.themeSecondaryText)
            .padding(.horizontal, 4)
    }

    private func routeLink(_ route: Route) -> some View {
        NavigationLink(value: route) {
            row(route.title, symbol: route.icon, accent: route == .help ? .themeSecondaryText : .themePrimary,
                subtitle: route.subtitle, showsChevron: true)
        }
        .buttonStyle(.plain)
    }

    private func row(
        _ title: String, symbol: String, accent: Color, titleColor: Color = .themeText,
        subtitle: String? = nil, showsChevron: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(accent)
                .frame(width: 40, height: 40)
                .background(accent.opacity(0.08), in: .rect(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(titleColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.themeMutedText)
            }
        }
        .padding(14)
        .background(Color.themeSurface, in: .rect(cornerRadius: 17))
        .contentShape(.rect)
    }

    @ContentBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .personal:
            if let settings { PersonalInfoView(profile: profile, avatarURL: avatarURL, actions: settings) }
        case .documents:
            if let documents { DocumentsView(actions: documents) }
        case .security:
            if let settings { SecuritySettingsView(changePassword: settings.changePassword) }
        case .notifications:
            if let settings {
                NotificationSettingsView(
                    loadSettings: settings.loadNotificationSettings, saveSettings: settings.saveNotificationSettings
                )
            }
        case .help:
            if let settings { HelpCenterView(loadTopics: settings.loadHelp) }
        }
    }

    private func signOut() {
        do {
            try onSignOut()
        } catch {
            signOutError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(profile: .settingsPreview, onSignOut: {}, settings: .preview, documents: .preview)
    }
    .tint(Color.themePrimary)
}
