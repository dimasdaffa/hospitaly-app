//
//  DoctorResponse.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct DoctorResponse: Decodable {
    struct Practice: Decodable {
        let name: String
        let address: String?
        let room: String?
        let fee: Int?
    }

    struct Slot: Decodable {
        let date: String
        let time: String
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
}
