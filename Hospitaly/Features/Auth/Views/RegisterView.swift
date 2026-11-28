//
//  RegisterView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct RegisterView: View {
    private enum Field: Hashable {
        case name, email, password, confirmation
    }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var model = RegisterViewModel()

    let onRegister: @MainActor (RegisterRequest) async throws -> String
    let onRegistered: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                fields
                    .disabled(model.isSubmitting)
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(model.isSubmitting)
            }
        }
        .interactiveDismissDisabled(model.isSubmitting)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("RS Permata Sehat", systemImage: "cross.case.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeSurface.opacity(0.88))

            Text("Create Patient Account")
                .font(.title.bold())
                .foregroundStyle(Color.themeSurface)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            CrimsonHeaderBackdrop().clipShape(.rect(cornerRadius: Theme.cardRadius))
        }
    }

    private var fields: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: 16) {
            field("Full Name", focus: .name) {
                TextField("Full Name", text: $model.name, prompt: Text(""))
                    .textContentType(.name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
            }

            field("Email", focus: .email) {
                TextField("Email", text: $model.email, prompt: Text("name@example.com"))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            VStack(alignment: .leading, spacing: 6) {
                field("Password", focus: .password) {
                    SecureField("Password", text: $model.password, prompt: Text(""))
                        .textContentType(.newPassword)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmation }
                }

                Text("Use at least 8 characters.")
                    .font(.footnote)
                    .foregroundStyle(Color.themeSecondaryText)
            }

            field("Confirm Password", focus: .confirmation) {
                SecureField("Confirm Password", text: $model.confirmation, prompt: Text(""))
                    .textContentType(.newPassword)
                    .submitLabel(.go)
                    .onSubmit(register)
            }

            if let message = registrationMessage {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.themeCrimsonInk)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.themeGlassRose, in: .rect(cornerRadius: 12))
            }
        }
        .padding(16)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .environment(\.colorScheme, .light)
    }

    private func field<Control: View>(
        _ title: LocalizedStringKey, focus: Field, @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeText)

            control()
                .focused($focusedField, equals: focus)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.themeText)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(focusedField == focus ? Color.themeCrimsonInk : Color.themeOutline)
                        .allowsHitTesting(false)
                }
        }
    }

    private var actionBar: some View {
        PrimaryActionButton(
            title: model.isSubmitting ? "Creating Account…" : "Create Account",
            icon: "arrow.right", isLoading: model.isSubmitting, action: register
        )
        .disabled(!model.canRegister)
        .padding(.horizontal, Theme.contentInset)
        .padding(.vertical, 10)
        .frame(maxWidth: Theme.dashboardWidth)
        .frame(maxWidth: .infinity)
        .hospitalyActionBar()
    }

    private var registrationMessage: String? {
        if let error = model.errorMessage { return error }
        if model.password.utf8.count > 72 { return "Choose a shorter password." }
        if !model.confirmation.isEmpty, model.confirmation != model.password {
            return "The passwords do not match."
        }
        return nil
    }

    private func register() {
        guard model.canRegister else { return }
        focusedField = nil

        Task {
            if let email = await model.register(using: onRegister) {
                onRegistered(email)
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView(onRegister: { $0.email }, onRegistered: { _ in })
    }
}

#Preview("Email Already Registered") {
    NavigationStack {
        RegisterView(onRegister: { _ in throw APIError.httpStatus(409) }, onRegistered: { _ in })
    }
}
