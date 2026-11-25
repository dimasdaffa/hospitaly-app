//
//  ProfileView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    enum Route: Hashable {
        case documents
    }

    @State private var signOutError: String?

    let profile: UserProfile
    let onSignOut: @MainActor () throws -> Void
    var showsDocuments = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                identityCard

                if showsDocuments {
                    NavigationLink(value: Route.documents) { documentsRow }
                        .buttonStyle(.plain)
                }

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

    private var documentsRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(Color.themePrimary)
                .frame(width: 40, height: 40)
                .background(Color.themePrimary.opacity(0.08), in: .rect(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 4) {
                Text("Documents & BPJS")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeText)
                Text("Insurance and patient documents")
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.themeMutedText)
        }
        .padding(14)
        .background(Color.themeSurface, in: .rect(cornerRadius: 17))
        .contentShape(.rect)
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
            onSignOut: {},
            showsDocuments: true
        )
        .navigationDestination(for: ProfileView.Route.self) { _ in
            DocumentsView(actions: .preview)
        }
    }
}
