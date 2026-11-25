//
//  RegisterViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation
import Observation

@Observable
final class RegisterViewModel {
    var name = ""
    var email = ""
    var password = ""
    var confirmation = ""
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    var canRegister: Bool {
        !isSubmitting && !cleanName.isEmpty && cleanName.unicodeScalars.count <= 255 &&
            AccountInput.validEmail(cleanEmail) && AccountInput.validNewPassword(password) && password == confirmation
    }

    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var cleanEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }

    func register(using request: @MainActor (RegisterRequest) async throws -> String) async -> String? {
        guard canRegister, !Task.isCancelled else { return nil }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let registered = try await request(RegisterRequest(name: cleanName, email: cleanEmail, password: password))
            password = ""
            confirmation = ""
            return registered
        } catch APIError.httpStatus(409) {
            errorMessage = "This email is already registered. Sign in with it or use another address."
        } catch where !Task.isCancelled && !(error is CancellationError) {
            errorMessage = error.localizedDescription
        } catch {
            return nil
        }
        return nil
    }
}
