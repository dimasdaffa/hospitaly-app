//
//  Conversation.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct Conversation: Identifiable, Equatable, Sendable {
    let peerId: UUID
    let name: String
    let specialty: String?
    let avatarURL: URL?
    let latestMessage: Message
    let unreadCount: Int

    var id: UUID { peerId }

    var peer: MessagePeer {
        MessagePeer(id: peerId, name: name, specialty: specialty, avatarURL: avatarURL)
    }
}
