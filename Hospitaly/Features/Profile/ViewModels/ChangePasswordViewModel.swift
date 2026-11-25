//
//  ChangePasswordViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation
import Observation

@Observable
final class ChangePasswordViewModel {
    var currentPassword = ""
    var newPassword = ""
    var confirmation = ""

    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var didChange = false

    var canSave: Bool {
        !isSaving && !currentPassword.isEmpty && newPassword != currentPassword &&
            AccountInput.validNewPassword(newPassword) && newPassword == confirmation
    }

    func save(using request: @MainActor (ChangePasswordRequest) async throws -> Void) async {
        guard canSave, !Task.isCancelled else { return }
        isSaving = true
        errorMessage = nil
        didChange = false
        defer { isSaving = false }

        do {
            try await request(ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword))
            currentPassword = ""
            newPassword = ""
            confirmation = ""
            didChange = true
        } catch where !Task.isCancelled && !(error is CancellationError) {
            errorMessage = error.localizedDescription
        } catch {
            return
        }
    }
}
