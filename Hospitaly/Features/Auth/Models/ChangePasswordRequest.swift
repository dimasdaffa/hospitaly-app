//
//  ChangePasswordRequest.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}
