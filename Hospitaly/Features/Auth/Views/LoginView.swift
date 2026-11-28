//
//  LoginView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @State private var showsRegistration = false
    @State private var didRegister = false

    let onSignIn: @MainActor (LoginRequest) async throws -> Void
    let onCheckConnection: @MainActor () async throws -> Void
    var onRegister: (@MainActor (RegisterRequest) async throws -> String)?

    var body: some View {
        @Bindable var model = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(spacing: 12) {
                    TextField("Email", text: $model.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(14)
                        .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 12))

                    SecureField("Password", text: $model.password)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .onSubmit(signIn)
                        .padding(14)
                        .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 12))
                }
                .textFieldStyle(.plain)
                .padding(14)
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                .environment(\.colorScheme, .light)
                .disabled(viewModel.isSigningIn)

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                } else if didRegister {
                    Text("Account created. Sign in with your new password.")
                        .font(.footnote)
                        .foregroundStyle(Color.themeAvailableText)
                }

                PrimaryActionButton(
                    title: viewModel.isSigningIn ? "Signing In…" : "Sign In",
                    icon: "arrow.right",
                    isLoading: viewModel.isSigningIn,
                    action: signIn
                )
                .disabled(!viewModel.canSignIn)

                if onRegister != nil {
                    Button("Create Patient Account") { showsRegistration = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeCrimsonInk)
                        .disabled(viewModel.isSigningIn)
                }

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
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .sheet(isPresented: $showsRegistration) {
            if let onRegister {
                NavigationStack {
                    RegisterView(onRegister: onRegister) { email in
                        viewModel.useRegisteredEmail(email)
                        didRegister = true
                    }
                }
                .tint(Color.themePrimary)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "cross.case.fill")
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(Color.themeSurface.opacity(0.18), in: .rect(cornerRadius: 14))
                .padding(.bottom, 6)

            Text("RS Permata Sehat")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeSurface.opacity(0.90))

            Text("Patient Sign In")
                .font(.largeTitle.bold())
        }
        .foregroundStyle(Color.themeSurface)
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.crimsonGradient, in: .rect(cornerRadius: Theme.heroRadius))
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
        if viewModel.canSignIn { didRegister = false }
        Task { await viewModel.signIn(using: onSignIn) }
    }
}

#Preview {
    LoginView(onSignIn: { _ in }, onCheckConnection: {}, onRegister: { $0.email })
}
