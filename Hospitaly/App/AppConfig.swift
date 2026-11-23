//
//  AppConfig.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

enum AppConfig {
    static func apiBaseURL() throws -> URL {
        let configuredURL = ProcessInfo.processInfo.environment["HOSPITALY_API_BASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "HospitalyAPIBaseURL") as? String

        #if DEBUG
        let urlString = configuredURL ?? "http://localhost:8081"
        let allowedSchemes = ["http", "https"]
        #else
        let urlString = configuredURL ?? ""
        let allowedSchemes = ["https"]
        #endif

        guard let components = URLComponents(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = components.scheme?.lowercased(),
              allowedSchemes.contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              let url = components.url else {
            throw APIError.invalidConfiguration
        }

        return url
    }
}
