//
//  SessionStore.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class SessionStore {
    enum Phase: Equatable {
        case restoring
        case signedOut
        case signedIn(UserProfile)
        case restoreFailed(String)
    }

    private(set) var phase: Phase
    @ObservationIgnored private var isRestoring = false
    @ObservationIgnored private var isSigningIn = false
    @ObservationIgnored private var isRegistering = false

    private let authService: AuthService
    private let profileService: ProfileService
    private let tokenStore: TokenStore

    init(
        authService: AuthService,
        profileService: ProfileService,
        tokenStore: TokenStore,
        phase: Phase = .restoring
    ) {
        self.authService = authService
        self.profileService = profileService
        self.tokenStore = tokenStore
        self.phase = phase
    }

    func restore() async {
        switch phase {
        case .signedIn, .signedOut:
            return
        case .restoring, .restoreFailed:
            break
        }

        guard !isRestoring else { return }
        isRestoring = true
        phase = .restoring
        defer { isRestoring = false }

        do {
            guard let token = try tokenStore.read() else {
                phase = .signedOut
                return
            }

            let profile = try await patientProfile(token: token)
            try Task.checkCancellation()
            phase = .signedIn(profile)
        } catch APIError.httpStatus(401) {
            discardSavedSession()
        } catch SessionError.patientAccountRequired {
            discardSavedSession()
        } catch TokenStoreError.invalidToken {
            discardSavedSession()
        } catch is CancellationError {
            phase = .restoreFailed("Session restoration was interrupted. Try again.")
        } catch {
            phase = .restoreFailed(error.localizedDescription)
        }
    }

    func signIn(_ request: LoginRequest) async throws {
        guard phase == .signedOut, !isSigningIn, !isRegistering else { throw SessionError.signInUnavailable }
        isSigningIn = true
        defer { isSigningIn = false }

        let token: String
        do {
            token = try await authService.signIn(request)
        } catch APIError.httpStatus(401) {
            throw SessionError.invalidCredentials
        }

        let profile = try await patientProfile(token: token)
        try Task.checkCancellation()
        try tokenStore.save(token)
        phase = .signedIn(profile)
    }

    func signOut() throws {
        try tokenStore.remove()
        phase = .signedOut
    }

    func discardSavedSession() {
        do {
            try signOut()
        } catch {
            phase = .restoreFailed(error.localizedDescription)
        }
    }

    func checkConnection() async throws {
        try await authService.checkConnection()
    }

    func register(_ request: RegisterRequest) async throws -> String {
        guard phase == .signedOut, !isSigningIn, !isRegistering else { throw SessionError.signInUnavailable }
        isRegistering = true
        defer { isRegistering = false }
        return try await authService.register(request)
    }

    func updateProfile(_ request: ProfileUpdateRequest) async throws {
        guard case .signedIn(let current) = phase else { throw APIError.httpStatus(401) }
        try await withPatientToken { token in
            let updated = try await profileService.update(request, token: token)
            guard updated.id == current.id, updated.role == "patient" else { throw APIError.invalidPayload }
            try Task.checkCancellation()
            guard case .signedIn(let active) = phase, active.id == current.id,
                  try tokenStore.read() == token else { throw CancellationError() }
            phase = .signedIn(updated)
        }
    }

    func uploadProfilePhoto(_ jpeg: Data) async throws -> String {
        try await withPatientToken { try await profileService.uploadPhoto(jpeg, token: $0) }
    }

    func profileAvatarURL(_ profile: UserProfile) -> URL? {
        profileService.avatarURL(profile)
    }

    func helpTopics() async throws -> [HelpTopic] {
        try await withPatientToken { try await profileService.helpTopics(token: $0) }
    }

    func changePassword(_ request: ChangePasswordRequest) async throws {
        try await withPatientToken { token in
            do {
                try await authService.changePassword(request, token: token)
            } catch APIError.httpStatus(401) {
                // Vapor also returns 401 when the current password is wrong.
                _ = try await patientProfile(token: token)
                throw SessionError.incorrectCurrentPassword
            }
        }
    }

    func withPatientToken<Response>(_ request: @MainActor (String) async throws -> Response) async throws -> Response {
        guard case .signedIn = phase else { throw APIError.httpStatus(401) }
        guard let token = try tokenStore.read() else {
            discardSavedSession()
            throw APIError.httpStatus(401)
        }

        do {
            return try await request(token)
        } catch APIError.httpStatus(401) {
            if !Task.isCancelled, (try? tokenStore.read()) == token {
                discardSavedSession()
            }
            throw APIError.httpStatus(401)
        }
    }

    private func patientProfile(token: String) async throws -> UserProfile {
        let profile = try await profileService.currentUser(token: token)
        guard profile.role == "patient" else { throw SessionError.patientAccountRequired }
        return profile
    }
}
