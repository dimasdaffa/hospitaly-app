//
//  HospitalyApp.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 22/11/26.
//

import Foundation
import SwiftUI

@main
struct HospitalyApp: App {
    @State private var launch: Result<SessionStore, Error> = Result {
        let baseURL = try AppConfig.apiBaseURL()
        let client = APIClient(baseURL: baseURL)
        return SessionStore(
            authService: AuthService(client: client),
            profileService: ProfileService(client: client),
            tokenStore: TokenStore(account: baseURL.absoluteString)
        )
    }

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .success(let session):
                RootView(session: session)
            case .failure(let error):
                ContentUnavailableView(
                    "API Configuration Required",
                    systemImage: "network.slash",
                    description: Text(error.localizedDescription)
                )
            }
        }
    }
}
