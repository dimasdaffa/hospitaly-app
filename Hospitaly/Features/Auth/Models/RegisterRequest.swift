//
//  RegisterRequest.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let role = "patient"
}
