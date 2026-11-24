//
//  MessagePeer.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct MessagePeer: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let specialty: String?
    let avatarURL: URL?

    init(id: UUID, name: String, specialty: String?, avatarURL: URL?) {
        self.id = id
        self.name = name
        self.specialty = specialty
        self.avatarURL = avatarURL
    }

    init?(doctor: Doctor) {
        guard let userId = doctor.userId else { return nil }
        self.init(id: userId, name: doctor.name, specialty: doctor.specialty, avatarURL: doctor.avatarURL)
    }
}
