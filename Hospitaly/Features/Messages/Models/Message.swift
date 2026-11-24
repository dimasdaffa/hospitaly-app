//
//  Message.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct Message: Decodable, Identifiable, Equatable, Sendable {
    let id: UUID
    let senderId: UUID
    let senderName: String
    let receiverId: UUID
    let content: String
    var isRead: Bool
    let createdAt: Date?
}
