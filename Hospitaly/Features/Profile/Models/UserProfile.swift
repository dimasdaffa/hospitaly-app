//
//  UserProfile.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct UserProfile: Decodable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let role: String
    let patientNumber: String?
}
