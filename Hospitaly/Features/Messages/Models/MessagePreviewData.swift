//
//  MessagePreviewData.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

extension MessagePeer {
    static let samplePatientID = UUID()
    static let sample = MessagePeer(id: UUID(), name: "Dr. Sample", specialty: "General Practice", avatarURL: nil)
}

extension Doctor {
    static let messageSample: Doctor = {
        var doctor = Doctor.samples[0]
        doctor.userId = MessagePeer.sample.id
        return doctor
    }()
}

extension Message {
    static let sampleOutgoing = Message(
        id: UUID(), senderId: MessagePeer.samplePatientID, senderName: "Demo Patient",
        receiverId: MessagePeer.sample.id, content: "Hi, is my follow-up confirmed?",
        isRead: true, createdAt: .now.addingTimeInterval(-1_800)
    )

    static let sampleIncoming = Message(
        id: UUID(), senderId: MessagePeer.sample.id, senderName: MessagePeer.sample.name,
        receiverId: MessagePeer.samplePatientID, content: "Yes, your follow-up is confirmed.",
        isRead: false, createdAt: .now.addingTimeInterval(-1_200)
    )
}

extension Conversation {
    static let sample = Conversation(
        peerId: MessagePeer.sample.id, name: MessagePeer.sample.name, specialty: MessagePeer.sample.specialty,
        avatarURL: nil, latestMessage: .sampleIncoming, unreadCount: 1
    )
}

extension MessageActions {
    static let preview = makePreview(isEmpty: false)
    static let emptyPreview = makePreview(isEmpty: true)

    private static func makePreview(isEmpty: Bool) -> MessageActions {
        MessageActions(
            loadInbox: { term in
                let sample = Conversation.sample
                let matches = term.isEmpty || sample.name.localizedStandardContains(term) ||
                    sample.latestMessage.content.localizedStandardContains(term)
                return !isEmpty && matches ? [sample] : []
            },
            loadMessages: { peer, _ in
                isEmpty || peer != MessagePeer.sample.id ? [] : [.sampleOutgoing, .sampleIncoming]
            },
            send: { peer, draft in
                Message(
                    id: UUID(), senderId: MessagePeer.samplePatientID, senderName: "Demo Patient",
                    receiverId: peer, content: draft, isRead: false, createdAt: .now
                )
            },
            markRead: { _ in }
        )
    }
}
