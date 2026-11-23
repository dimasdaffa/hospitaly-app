//
//  AuthService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

struct AuthService {
    let client: APIClient

    func signIn(_ request: LoginRequest) async throws -> String {
        let response: LoginResponse = try await client.post("api/auth/login", body: request)
        guard !response.token.isEmpty else { throw APIError.invalidPayload }
        return response.token
    }

    func checkConnection() async throws {
        try await client.checkConnection()
    }
}
