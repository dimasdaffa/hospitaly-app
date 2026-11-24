//
//  MessageActions.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct MessageActions {
    let loadInbox: @MainActor (String) async throws -> [Conversation]
    let loadMessages: @MainActor (UUID, Int) async throws -> [Message]
    let send: @MainActor (UUID, String) async throws -> Message
    let markRead: @MainActor (UUID) async throws -> Void
}
