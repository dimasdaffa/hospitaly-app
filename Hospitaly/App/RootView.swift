//
//  RootView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct RootView: View {
    private enum AppTab: Hashable {
        case doctors
        case profile
    }

    @State private var selectedTab: AppTab = .profile

    let session: SessionStore

    var body: some View {
        Group {
            switch session.phase {
            case .restoring:
                ProgressView("Restoring session…")
            case .restoreFailed(let message):
                restoreError(message)
            case .signedOut:
                LoginView(
                    onSignIn: { request in
                        try await session.signIn(request)
                        selectedTab = .profile
                    },
                    onCheckConnection: session.checkConnection
                )
            case .signedIn(let profile):
                signedInTabs(profile)
            }
        }
        .tint(.themePrimary)
        .task {
            if session.phase == .restoring {
                await session.restore()
            }
        }
    }

    private func restoreError(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Restore Session", systemImage: "person.crop.circle.badge.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await session.restore() }
            }
            .buttonStyle(.borderedProminent)

            Button("Sign In Again", action: session.discardSavedSession)
        }
    }

    private func signedInTabs(_ profile: UserProfile) -> some View {
        TabView(selection: $selectedTab) {
            Tab("Doctors", systemImage: "stethoscope", value: AppTab.doctors) {
                DoctorListView()
            }

            Tab("Profile", systemImage: "person", value: AppTab.profile) {
                NavigationStack {
                    ProfileView(profile: profile, onSignOut: session.signOut)
                }
            }
        }
    }
}

#Preview("Signed Out") {
    let client = APIClient(baseURL: URL(filePath: "/preview"))
    RootView(session: SessionStore(
        authService: AuthService(client: client),
        profileService: ProfileService(client: client),
        tokenStore: TokenStore(account: "preview"),
        phase: .signedOut
    ))
}

#Preview("Restore Failed") {
    let client = APIClient(baseURL: URL(filePath: "/preview"))
    RootView(session: SessionStore(
        authService: AuthService(client: client),
        profileService: ProfileService(client: client),
        tokenStore: TokenStore(account: "preview"),
        phase: .restoreFailed("Could not reach the server. Check your connection and try again.")
    ))
}
