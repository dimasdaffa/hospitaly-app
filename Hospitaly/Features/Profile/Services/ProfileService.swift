//
//  ProfileService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

struct ProfileService {
    let client: APIClient

    func currentUser(token: String) async throws -> UserProfile {
        try await client.get("api/users/me", token: token)
    }
}
