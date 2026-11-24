//
//  MessageService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct MessageService {
    static let pageSize = 50
    static let lastPage = 10_000
    static let characterLimit = 255

    private struct ConversationResponse: Decodable {
        let peerId: UUID
        let name: String
        let specialty: String?
        let avatarURL: String?
        let latestMessage: Message
        let unreadCount: Int
    }

    private struct SendRequest: Encodable {
        let receiverId: UUID
        let content: String
    }

    let client: APIClient

    func inbox(query: String, token: String) async throws -> [Conversation] {
        let items = query.isEmpty ? [] : [URLQueryItem(name: "q", value: query)]
        let rows: [ConversationResponse] = try await client.get(
            "api/messages/conversations", token: token, query: items
        )
        return rows.map { row in
            Conversation(
                peerId: row.peerId, name: row.name, specialty: row.specialty,
                avatarURL: row.avatarURL.flatMap(client.publicImageURL),
                latestMessage: row.latestMessage, unreadCount: row.unreadCount
            )
        }
    }

    func thread(peerID: UUID, page: Int, token: String) async throws -> [Message] {
        try await client.get("api/messages", token: token, query: [
            URLQueryItem(name: "peerId", value: peerID.uuidString),
            URLQueryItem(name: "limit", value: String(Self.pageSize)),
            URLQueryItem(name: "page", value: String(page))
        ])
    }

    func send(receiverID: UUID, content: String, token: String) async throws -> Message {
        try await client.post(
            "api/messages", body: SendRequest(receiverId: receiverID, content: content), token: token
        )
    }

    func markRead(_ id: UUID, token: String) async throws {
        try await client.put("api/messages/\(id)/read", token: token)
    }
}
