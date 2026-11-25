//
//  AccountInput.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

enum AccountInput {
    static func validEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && parts.allSatisfy { !$0.isEmpty }
            && !email.contains(where: \.isWhitespace) && email.utf8.count <= 255
    }

    static func validNewPassword(_ password: String) -> Bool {
        password.count >= 8 && password.utf8.count <= 72 && !password.utf8.contains(0)
    }
}
