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
    @State private var launch: Result<
        (session: SessionStore, doctorService: DoctorService, appointmentService: AppointmentService),
        Error
    > = Result {
        let baseURL = try AppConfig.apiBaseURL()
        let client = APIClient(baseURL: baseURL)
        let session = SessionStore(
            authService: AuthService(client: client),
            profileService: ProfileService(client: client),
            tokenStore: TokenStore(account: baseURL.absoluteString)
        )
        return (session, DoctorService(client: client), AppointmentService(client: client))
    }

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .success(let dependencies):
                RootView(
                    session: dependencies.session,
                    doctorService: dependencies.doctorService,
                    appointmentService: dependencies.appointmentService
                )
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
