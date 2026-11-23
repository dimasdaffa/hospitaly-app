//
//  ProfileView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    @State private var signOutError: String?

    let profile: UserProfile
    let onSignOut: @MainActor () throws -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                identityCard

                if let signOutError {
                    Text(signOutError)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                }

                Button(
                    "Log Out", systemImage: "rectangle.portrait.and.arrow.right",
                    role: .destructive, action: signOut
                )
            }
            .frame(maxWidth: 440)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var identityCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color.themePrimary)

            Text(profile.name)
                .font(.title2.bold())
                .foregroundStyle(Color.themeText)

            if let patientNumber = profile.patientNumber {
                Text("Patient ID #\(patientNumber)")
                    .font(.subheadline.weight(.semibold))
            }

            Text(profile.email)
                .font(.subheadline)
        }
        .foregroundStyle(Color.themeSecondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.themeSurface, in: RoundedRectangle(cornerRadius: 20))
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
        ProfileView(
            profile: UserProfile(
                id: UUID(),
                name: "Demo Patient",
                email: "patient@example.test",
                role: "patient",
                patientNumber: "PS-DEMO"
            ),
            onSignOut: {}
        )
    }
}
