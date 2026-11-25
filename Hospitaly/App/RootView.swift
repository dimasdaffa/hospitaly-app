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
    let notificationService: NotificationService
    let carePlanService: CarePlanService
    let healthService: HealthService
    let medicalRecordsService: MedicalRecordsService
    let messageService: MessageService
    let documentService: DocumentService

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
                    onCheckConnection: session.checkConnection,
                    onRegister: session.register
                )
            case .signedIn(let profile):
                MainTabView(
                    profile: profile, onSignOut: session.signOut,
                    loadDoctors: loadDoctors, loadDoctorDetails: loadDoctorDetails,
                    setFavorite: setFavorite,
                    loadAppointments: loadAppointments, bookAppointment: bookAppointment,
                    appointmentManagement: AppointmentManagement(
                        loadSlots: loadReplacementSlots, reschedule: rescheduleAppointment, cancel: cancelAppointment
                    ),
                    loadNotifications: loadNotifications, markNotificationRead: markNotificationRead,
                    carePlanActions: CarePlanActions(load: loadCarePlan, markTaken: markDoseTaken),
                    healthTrackerActions: HealthTrackerActions(load: loadHealthReadings, save: saveHealthReading),
                    medicalRecordsActions: medicalRecordsActions,
                    messageActions: messageActions,
                    documentsActions: documentsActions,
                    profileSettings: profileSettings,
                    profileAvatarURL: session.profileAvatarURL(profile)
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

    private func setFavorite(id: String, isFavorite: Bool) async throws {
        try await session.withPatientToken {
            try await doctorService.setFavorite(id: id, isFavorite: isFavorite, token: $0)
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

    private func loadNotifications() async throws -> [PatientNotification] {
        try await session.withPatientToken { token in
            try await notificationService.list(token: token)
        }
    }

    private func markNotificationRead(_ id: UUID) async throws {
        try await session.withPatientToken { token in
            try await notificationService.markRead(id: id, token: token)
        }
    }

    private func loadCarePlan(date: String) async throws -> [CarePlanEntry] {
        try await session.withPatientToken { token in
            try await carePlanService.list(date: date, token: token)
        }
    }

    private func markDoseTaken(_ entry: CarePlanEntry) async throws -> CarePlanEntry {
        try await session.withPatientToken { token in
            try await carePlanService.markTaken(entry, token: token)
        }
    }

    private func loadHealthReadings(metric: HealthMetric, range: ClosedRange<Date>) async throws -> [HealthReading] {
        try await session.withPatientToken { token in
            try await healthService.list(metric: metric, from: range.lowerBound, to: range.upperBound, token: token)
        }
    }

    private func saveHealthReading(_ request: HealthReadingRequest) async throws -> HealthReading {
        try await session.withPatientToken { token in
            try await healthService.log(request, token: token)
        }
    }

    private var medicalRecordsActions: MedicalRecordsActions {
        MedicalRecordsActions(
            loadHistory: {
                try await session.withPatientToken { try await medicalRecordsService.history(token: $0) }
            },
            loadRecord: { id in
                try await session.withPatientToken { try await medicalRecordsService.record(id, token: $0) }
            },
            loadAttachments: { id in
                try await session.withPatientToken { try await medicalRecordsService.attachments(id, token: $0) }
            },
            loadLab: { id in
                try await session.withPatientToken { try await medicalRecordsService.lab(id, token: $0) }
            },
            download: { file in
                try await session.withPatientToken { try await medicalRecordsService.download(file, token: $0) }
            },
            displayDoctor: { doctorService.displayDoctor($0) }
        )
    }

    private var messageActions: MessageActions {
        MessageActions(
            loadInbox: { query in
                try await session.withPatientToken { try await messageService.inbox(query: query, token: $0) }
            },
            loadMessages: { peerID, page in
                try await session.withPatientToken {
                    try await messageService.thread(peerID: peerID, page: page, token: $0)
                }
            },
            send: { receiverID, content in
                try await session.withPatientToken {
                    try await messageService.send(receiverID: receiverID, content: content, token: $0)
                }
            },
            markRead: { id in
                try await session.withPatientToken { try await messageService.markRead(id, token: $0) }
            }
        )
    }

    private var documentsActions: DocumentsActions {
        DocumentsActions(
            load: {
                try await session.withPatientToken { try await documentService.list(token: $0) }
            },
            loadHistory: {
                try await session.withPatientToken { try await documentService.history(token: $0) }
            },
            upload: { draft in
                try await session.withPatientToken { try await documentService.upload(draft, token: $0) }
            },
            update: { id, draft in
                try await session.withPatientToken { try await documentService.update(id, draft: draft, token: $0) }
            },
            delete: { id in
                try await session.withPatientToken { try await documentService.delete(id, token: $0) }
            },
            download: { file in
                try await session.withPatientToken { try await documentService.download(file, token: $0) }
            }
        )
    }

    private var profileSettings: ProfileSettingsActions {
        ProfileSettingsActions(
            updateProfile: session.updateProfile,
            uploadPhoto: session.uploadProfilePhoto,
            changePassword: session.changePassword,
            loadNotificationSettings: {
                try await session.withPatientToken { try await notificationService.settings(token: $0) }
            },
            saveNotificationSettings: { settings in
                try await session.withPatientToken { try await notificationService.updateSettings(settings, token: $0) }
            },
            loadHelp: session.helpTopics
        )
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
    ), doctorService: DoctorService(client: client),
       appointmentService: AppointmentService(client: client), notificationService: NotificationService(client: client),
       carePlanService: CarePlanService(client: client), healthService: HealthService(client: client),
       medicalRecordsService: MedicalRecordsService(client: client), messageService: MessageService(client: client),
       documentService: DocumentService(client: client))
}

#Preview("Restore Failed") {
    let client = APIClient(baseURL: URL(filePath: "/preview"))
    RootView(session: SessionStore(
        authService: AuthService(client: client),
        profileService: ProfileService(client: client),
        tokenStore: TokenStore(account: "preview"),
        phase: .restoreFailed("Could not reach the server. Check your connection and try again.")
    ), doctorService: DoctorService(client: client),
       appointmentService: AppointmentService(client: client), notificationService: NotificationService(client: client),
       carePlanService: CarePlanService(client: client), healthService: HealthService(client: client),
       medicalRecordsService: MedicalRecordsService(client: client), messageService: MessageService(client: client),
       documentService: DocumentService(client: client))
}
