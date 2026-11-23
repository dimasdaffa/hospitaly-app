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
        guard phase == .signedOut, !isSigningIn else { throw SessionError.signInUnavailable }
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

    private func patientProfile(token: String) async throws -> UserProfile {
        let profile = try await profileService.currentUser(token: token)
        guard profile.role == "patient" else { throw SessionError.patientAccountRequired }
        return profile
    }
}
