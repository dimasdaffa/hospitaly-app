//
//  TokenStoreError.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

enum TokenStoreError: LocalizedError {
    case unavailable
    case invalidToken

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Could not access the saved session. Unlock your device and try again."
        case .invalidToken:
            "The saved session could not be read. Sign in again."
        }
    }
}
