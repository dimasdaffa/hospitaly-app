//
//  DoctorResponse.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct DoctorResponse: Decodable, Sendable {
    struct Account: Decodable, Sendable {
        let id: UUID
    }

    struct Practice: Decodable, Sendable {
        let name: String
        let address: String?
        let room: String?
        let fee: Int?
        let currency: String?
    }

    struct Slot: Decodable, Sendable {
        let date: String
        let time: String
        let endTime: String
        let available: Bool
    }

    let id: UUID
    let name: String
    let specialty: String
    let experience: Int
    let rating: Double
    let bio: String?
    let license: String?
    let totalPatients: Int
    let avatarURL: String?
    let reviewCount: Int?
    let practice: Practice?
    let isFavorite: Bool?
    let nextAvailable: Slot?
    let userId: UUID?
    let user: Account?

    var messagingUserId: UUID? { userId ?? user?.id }
}
