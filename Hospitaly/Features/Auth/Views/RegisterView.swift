//
//  RegisterView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model = RegisterViewModel()

    let onRegister: @MainActor (RegisterRequest) async throws -> String
    let onRegistered: (String) -> Void

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                TextField("Full Name", text: $model.name)
                    .textContentType(.name)
                TextField("Email", text: $model.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $model.password)
                    .textContentType(.newPassword)
                SecureField("Confirm Password", text: $model.confirmation)
                    .textContentType(.newPassword)
            } header: {
                Text("Account Details")
            } footer: {
                Text("Use at least 8 characters for your password.")
            }

            if let message = registrationMessage {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                }
            }
        }
        .disabled(model.isSubmitting)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Create Patient Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(model.isSubmitting)
            }
        }
        .interactiveDismissDisabled(model.isSubmitting)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: model.isSubmitting ? "Creating Account…" : "Create Account") {
                Task {
                    if let email = await model.register(using: onRegister) {
                        onRegistered(email)
                        dismiss()
                    }
                }
            }
            .disabled(!model.canRegister)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.themeSurface, ignoresSafeAreaEdges: .bottom)
        }
    }

    private var registrationMessage: String? {
        if let error = model.errorMessage { return error }
        if model.password.utf8.count > 72 { return "Choose a shorter password." }
        if !model.confirmation.isEmpty, model.confirmation != model.password {
            return "The passwords do not match."
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        RegisterView(onRegister: { $0.email }, onRegistered: { _ in })
    }
}
