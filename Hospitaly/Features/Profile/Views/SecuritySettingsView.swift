//
//  SecuritySettingsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct SecuritySettingsView: View {
    @State private var model = ChangePasswordViewModel()
    let changePassword: @MainActor (ChangePasswordRequest) async throws -> Void

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                Label("Change Password", systemImage: "lock.shield")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeSurface)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        CrimsonHeaderBackdrop().clipShape(.rect(cornerRadius: Theme.cardRadius))
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                SecureField("Current Password", text: $model.currentPassword)
                    .textContentType(.password)
                SecureField("New Password", text: $model.newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm New Password", text: $model.confirmation)
                    .textContentType(.newPassword)
            } footer: {
                Text("Use at least 8 characters for your new password.")
            }

            if let message = securityMessage {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                }
            } else if model.didChange {
                Section {
                    Label("Password updated.", systemImage: "checkmark.circle")
                        .foregroundStyle(Color.themeAvailableText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .environment(\.colorScheme, .light)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .disabled(model.isSaving)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isSaving)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: model.isSaving ? "Updating…" : "Update Password", isLoading: model.isSaving) {
                Task { await model.save(using: changePassword) }
            }
            .disabled(!model.canSave)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .hospitalyActionBar()
        }
    }

    private var securityMessage: String? {
        if let error = model.errorMessage { return error }
        if model.newPassword.utf8.count > 72 { return "Choose a shorter password." }
        if !model.newPassword.isEmpty, model.currentPassword == model.newPassword {
            return "Enter a different new password."
        }
        if !model.confirmation.isEmpty, model.confirmation != model.newPassword {
            return "The new passwords do not match."
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        SecuritySettingsView(changePassword: { _ in })
    }
}
