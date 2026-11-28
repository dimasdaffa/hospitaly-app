//
//  ProfileService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct ProfileService {
    private struct UploadResponse: Decodable {
        let url: String
    }

    let client: APIClient

    func currentUser(token: String) async throws -> UserProfile {
        try await client.get("api/users/me", token: token)
    }

    func update(_ request: ProfileUpdateRequest, token: String) async throws -> UserProfile {
        try await client.put("api/users/me", body: request, token: token)
    }

    func uploadPhoto(_ jpeg: Data, token: String) async throws -> String {
        let boundary = "Hospitaly-\(UUID().uuidString)"
        var body = Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8)
        body.append(jpeg)
        body.append(contentsOf: "\r\n--\(boundary)--\r\n".utf8)

        let response: UploadResponse = try await client.sendMultipart(
            "api/upload", method: "POST", body: body, boundary: boundary, token: token
        )
        let prefix = "/uploads/"
        let suffix = ".jpg"
        guard response.url.hasPrefix(prefix), response.url.hasSuffix(suffix),
              UUID(uuidString: String(response.url.dropFirst(prefix.count).dropLast(suffix.count))) != nil else {
            throw APIError.invalidPayload
        }
        return response.url
    }

    func avatarURL(_ profile: UserProfile) -> URL? {
        profile.avatarURL.flatMap(client.publicImageURL)
    }
}
