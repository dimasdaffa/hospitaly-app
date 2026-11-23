//
//  APIError.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

enum APIError: LocalizedError {
    case invalidConfiguration
    case connectionFailed
    case invalidResponse
    case invalidPayload
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            "Set HOSPITALY_API_BASE_URL to a valid API URL. Release builds require HTTPS."
        case .connectionFailed:
            "Could not reach the server. Check your connection and try again."
        case .invalidResponse, .invalidPayload:
            "The server returned an unexpected response."
        case .httpStatus(let status):
            if status == 401 {
                "The server could not authenticate this request."
            } else {
                "The server returned HTTP \(status). Try again."
            }
        }
    }
}
