//
//  LoginView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()

    let onSignIn: @MainActor (LoginRequest) async throws -> Void
    let onCheckConnection: @MainActor () async throws -> Void

    var body: some View {
        @Bindable var model = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 16) {
                    TextField("Email", text: $model.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $model.password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit(signIn)
                }
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isSigningIn)

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                }

                PrimaryActionButton(
                    title: viewModel.isSigningIn ? "Signing In…" : "Sign In",
                    icon: "arrow.right",
                    action: signIn
                )
                .disabled(!viewModel.canSignIn)

                #if DEBUG
                connectionCheck
                #endif
            }
            .frame(maxWidth: 440)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .foregroundStyle(Color.themeText)
        .background(Color.themeDetailCanvas.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "cross.case.fill")
                .font(.title)
                .foregroundStyle(Color.themePrimary)
                .padding(.bottom, 8)

            Text("RS Permata Sehat")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themePrimary)

            Text("Patient Sign In")
                .font(.largeTitle.bold())
        }
    }

    #if DEBUG
    private var connectionCheck: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(viewModel.isCheckingConnection ? "Checking Connection…" : "Check API Connection") {
                Task { await viewModel.checkConnection(using: onCheckConnection) }
            }
            .disabled(viewModel.isCheckingConnection)
            .foregroundStyle(Color.themePrimary)

            if let message = viewModel.connectionMessage {
                Text(message)
                    .foregroundStyle(Color.themeSecondaryText)
            }
        }
        .font(.footnote)
    }
    #endif

    private func signIn() {
        Task { await viewModel.signIn(using: onSignIn) }
    }
}

#Preview {
    LoginView(onSignIn: { _ in }, onCheckConnection: {})
}
