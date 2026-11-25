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
    var phone: String? = nil
    var dateOfBirth: String? = nil
    var gender: String? = nil
    var address: String? = nil
    var city: String? = nil
    var province: String? = nil
    var postalCode: String? = nil
    var emergencyContact: String? = nil
    var emergencyPhone: String? = nil
    var avatarURL: String? = nil
}

extension UserProfile {
    static let settingsPreview = UserProfile(
        id: UUID(), name: "Demo Patient", email: "patient@example.test",
        role: "patient", patientNumber: "PS-DEMO", phone: "08000000000", city: "Jakarta"
    )
}
