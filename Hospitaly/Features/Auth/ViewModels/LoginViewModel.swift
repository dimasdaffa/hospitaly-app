//
//  LoginViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class LoginViewModel {
    var email = ""
    var password = ""

    private(set) var isSigningIn = false
    private(set) var isCheckingConnection = false
    private(set) var errorMessage: String?
    private(set) var connectionMessage: String?

    var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty && !isSigningIn
    }

    func signIn(using action: @MainActor (LoginRequest) async throws -> Void) async {
        guard canSignIn else { return }
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }

        let request = LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )

        do {
            try await action(request)
            password = ""
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkConnection(using action: @MainActor () async throws -> Void) async {
        guard !isCheckingConnection else { return }
        isCheckingConnection = true
        connectionMessage = nil
        defer { isCheckingConnection = false }

        do {
            try await action()
            connectionMessage = "Server is reachable."
        } catch is CancellationError {
            return
        } catch {
            connectionMessage = error.localizedDescription
        }
    }
}
