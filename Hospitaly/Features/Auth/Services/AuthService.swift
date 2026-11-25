//
//  AuthService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

struct AuthService {
    private struct RegistrationResponse: Decodable {
        let email: String
        let role: String
    }

    private struct ChangePasswordResponse: Decodable {
        let success: Bool
    }

    let client: APIClient

    func signIn(_ request: LoginRequest) async throws -> String {
        let response: LoginResponse = try await client.post("api/auth/login", body: request)
        guard !response.token.isEmpty else { throw APIError.invalidPayload }
        return response.token
    }

    func checkConnection() async throws {
        try await client.checkConnection()
    }

    func register(_ request: RegisterRequest) async throws -> String {
        let response: RegistrationResponse = try await client.post("api/auth/register", body: request)
        guard response.role == "patient", !response.email.isEmpty else { throw APIError.invalidPayload }
        return response.email
    }

    func changePassword(_ request: ChangePasswordRequest, token: String) async throws {
        let response: ChangePasswordResponse = try await client.post(
            "api/auth/change-password", body: request, token: token
        )
        guard response.success else { throw APIError.invalidPayload }
    }
}
