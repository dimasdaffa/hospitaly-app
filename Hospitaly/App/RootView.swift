//
//  RootView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct RootView: View {
    let session: SessionStore
    let doctorService: DoctorService
    let appointmentService: AppointmentService

    var body: some View {
        Group {
            switch session.phase {
            case .restoring:
                ProgressView("Restoring session…")
            case .restoreFailed(let message):
                restoreError(message)
            case .signedOut:
                LoginView(
                    onSignIn: session.signIn,
                    onCheckConnection: session.checkConnection
                )
            case .signedIn(let profile):
                MainTabView(
                    profile: profile, onSignOut: session.signOut,
                    loadDoctors: loadDoctors, loadDoctorDetails: loadDoctorDetails,
                    loadAppointments: loadAppointments, bookAppointment: bookAppointment,
                    appointmentManagement: AppointmentManagement(
                        loadSlots: loadReplacementSlots, reschedule: rescheduleAppointment, cancel: cancelAppointment
                    )
                )
            }
        }
        .tint(.themePrimary)
        .task {
            if session.phase == .restoring {
                await session.restore()
            }
        }
    }

    private func loadDoctors() async throws -> [Doctor] {
        try await session.withPatientToken { token in
            try await doctorService.list(token: token)
        }
    }

    private func loadDoctorDetails(id: String, range: ClosedRange<Date>) async throws -> DoctorDetailData {
        try await session.withPatientToken { token in
            try await doctorService.details(id: id, range: range, token: token)
        }
    }

    private func loadAppointments() async throws -> [Appointment] {
        try await session.withPatientToken { token in
            try await appointmentService.list(token: token)
        }
    }

    private func bookAppointment(_ booking: BookingRequest, doctor: Doctor) async throws -> Appointment {
        try await session.withPatientToken { token in
            try await appointmentService.book(booking, doctor: doctor, token: token)
        }
    }

    private func loadReplacementSlots(
        for appointment: Appointment, range: ClosedRange<Date>
    ) async throws -> [AppointmentSlot] {
        try await session.withPatientToken { token in
            try await doctorService.availability(id: appointment.doctor.id, range: range, token: token)
        }
    }

    private func rescheduleAppointment(_ appointment: Appointment, slot: AppointmentSlot) async throws -> Appointment {
        try await session.withPatientToken { token in
            try await appointmentService.reschedule(appointment, to: slot, token: token)
        }
    }

    private func cancelAppointment(_ appointment: Appointment, request: CancellationRequest) async throws -> Appointment {
        try await session.withPatientToken { token in
            try await appointmentService.cancel(appointment, request: request, token: token)
        }
    }

    private func restoreError(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Restore Session", systemImage: "person.crop.circle.badge.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await session.restore() }
            }
            .buttonStyle(.borderedProminent)

            Button("Sign In Again", action: session.discardSavedSession)
        }
    }
}

#Preview("Signed Out") {
    let client = APIClient(baseURL: URL(filePath: "/preview"))
    RootView(session: SessionStore(
        authService: AuthService(client: client),
        profileService: ProfileService(client: client),
        tokenStore: TokenStore(account: "preview"),
        phase: .signedOut
    ), doctorService: DoctorService(client: client), appointmentService: AppointmentService(client: client))
}

#Preview("Restore Failed") {
    let client = APIClient(baseURL: URL(filePath: "/preview"))
    RootView(session: SessionStore(
        authService: AuthService(client: client),
        profileService: ProfileService(client: client),
        tokenStore: TokenStore(account: "preview"),
        phase: .restoreFailed("Could not reach the server. Check your connection and try again.")
    ), doctorService: DoctorService(client: client), appointmentService: AppointmentService(client: client))
}
