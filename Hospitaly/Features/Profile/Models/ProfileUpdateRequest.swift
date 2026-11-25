//
//  ProfileUpdateRequest.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

struct ProfileUpdateRequest: Encodable {
    var name: String?
    var email: String?
    var phone: String?
    var dateOfBirth: String?
    var gender: String?
    var address: String?
    var city: String?
    var province: String?
    var postalCode: String?
    var emergencyContact: String?
    var emergencyPhone: String?
    var avatarURL: String?

    var isEmpty: Bool {
        [name, email, phone, dateOfBirth, gender, address, city, province, postalCode,
         emergencyContact, emergencyPhone, avatarURL].allSatisfy { $0 == nil }
    }
}
