//
//  SessionError.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

enum SessionError: LocalizedError {
    case invalidCredentials
    case patientAccountRequired
    case signInUnavailable
    case incorrectCurrentPassword

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            "Check your email and password and try again."
        case .patientAccountRequired:
            "Sign in with a patient account to use Hospitaly."
        case .signInUnavailable:
            "A session is already active or signing in."
        case .incorrectCurrentPassword:
            "Your current password is incorrect."
        }
    }
}
