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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: -Theme.heroOverlap) {
                    identity
                        .hospitalyPageHero(topInset: geometry.safeAreaInsets.top)

                    settingsContent
                        .padding(.horizontal, Theme.contentInset)
                        .frame(maxWidth: Theme.dashboardWidth)
                        .padding(.bottom, 24)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.container, edges: .top)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: Route.self, destination: destination)
    }

    private var identity: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Profile Settings")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.themeSurface.opacity(0.86))

                Text(profile.name)
                    .font(.largeTitle.bold())
                    .tracking(-0.8)
                    .foregroundStyle(Color.themeSurface)
                    .fixedSize(horizontal: false, vertical: true)

                if let patientNumber = profile.patientNumber {
                    Label("Patient ID #\(patientNumber)", systemImage: "person.text.rectangle")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Color.themeSurface.opacity(0.90))
                }

                Text(profile.email)
                    .font(.footnote)
                    .foregroundStyle(Color.themeSurface.opacity(0.86))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if settings != nil {
                NavigationLink(value: Route.personal) {
                    ProfileAvatar(url: avatarURL, size: 86)
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
                ProfileAvatar(url: avatarURL, size: 86)
            }
        }
    }

    private var accountRoutes: [Route] {
        var routes: [Route] = []
        if settings != nil { routes.append(.personal) }
        if documents != nil { routes.append(.documents) }
        if settings != nil { routes.append(contentsOf: [.security, .notifications]) }
        return routes
    }

    private var settingsContent: some View {
        let routes = accountRoutes

        return VStack(alignment: .leading, spacing: 18) {
            if !routes.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Account")
                        .font(.headline)
                        .foregroundStyle(Color.themeText)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 7)

                    ForEach(routes, id: \.self) { route in
                        if route != routes.first { rowDivider }
                        routeLink(route)
                    }
                }
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            }

            VStack(spacing: 0) {
                routeLink(.help)
                rowDivider

                Button(role: .destructive, action: signOut) {
                    row(
                        "Log Out", symbol: "rectangle.portrait.and.arrow.right", accent: .themeCrimsonInk,
                        titleColor: .themeCrimsonInk
                    )
                }
                .buttonStyle(.plain)
            }
            .hospitalyPanel()

            if let signOutError {
                Text(signOutError)
                    .font(.footnote)
                    .foregroundStyle(Color.themeCrimsonInk)
            }
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.themeDivider)
            .frame(height: 1)
            .padding(.leading, 64)
    }

    private func routeLink(_ route: Route) -> some View {
        NavigationLink(value: route) {
            row(route.title, symbol: route.icon, accent: route == .help ? .themeSecondaryText : .themeCrimsonInk,
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(.rect)
    }

    private func destination(_ route: Route) -> some View {
        Group {
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
                HelpCenterView()
            }
        }
        .toolbarVisibility(.visible, for: .navigationBar)
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
