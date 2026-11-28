//
//  MainTabView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    private enum HomeRoute: Hashable {
        case appointments(AppointmentPresentation?)
        case healthTracker, records, documents
    }

    @State private var selection: MainTab = .home
    @State private var doctorPath: [DoctorRoute] = []
    @State private var doctorSearchRequest: DoctorListView.SearchRequest?
    @State private var chatPath: [MessagePeer] = []
    @State private var profilePath: [ProfileView.Route] = []
    @State private var homePath = NavigationPath()
    @State private var demoAppointments = Appointment.samples
    @State private var isNotificationsPresented = false
    @State private var notifications = NotificationsViewModel()
    @State private var inbox = InboxViewModel()

    let profile: UserProfile
    let onSignOut: @MainActor () throws -> Void
    let loadDoctors: @MainActor () async throws -> [Doctor]
    var loadDoctorDetails: (@MainActor (String, ClosedRange<Date>) async throws -> DoctorDetailData)? = nil
    var setFavorite: (@MainActor (String, Bool) async throws -> Void)? = nil
    var loadAppointments: (@MainActor () async throws -> [Appointment])? = nil
    var bookAppointment: (@MainActor (BookingRequest, Doctor) async throws -> Appointment)? = nil
    var appointmentManagement: AppointmentManagement? = nil
    var loadNotifications: (@MainActor () async throws -> [PatientNotification])? = nil
    var markNotificationRead: (@MainActor (UUID) async throws -> Void)? = nil
    var carePlanActions: CarePlanActions? = nil
    var healthTrackerActions: HealthTrackerActions? = nil
    var medicalRecordsActions: MedicalRecordsActions? = nil
    var messageActions: MessageActions? = nil
    var documentsActions: DocumentsActions? = nil
    var profileSettings: ProfileSettingsActions? = nil
    var profileAvatarURL: URL? = nil

    var body: some View {
        tabs
            .task(id: profile.id) { await refreshInbox() }
            .task(id: selection) {
                if selection == .home, let loadNotifications {
                    await notifications.load(using: loadNotifications)
                }
            }
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            Tab(MainTab.home.title, systemImage: MainTab.home.symbol, value: MainTab.home) {
                NavigationStack(path: $homePath) {
                    home
                        .toolbarVisibility(.hidden, for: .navigationBar)
                        .navigationDestination(for: HomeRoute.self, destination: homeDestination)
                }
            }

            Tab(MainTab.doctors.title, systemImage: MainTab.doctors.symbol, value: MainTab.doctors) {
                DoctorListView(
                    path: $doctorPath, demoAppointments: $demoAppointments,
                    loadDoctors: loadDoctors, loadDoctorDetails: loadDoctorDetails,
                    setFavorite: setFavorite,
                    loadAppointments: loadAppointments, bookAppointment: bookAppointment,
                    appointmentManagement: appointmentManagement,
                    searchRequest: doctorSearchRequest
                )
            }

            Tab(MainTab.chat.title, systemImage: MainTab.chat.symbol, value: MainTab.chat) {
                chat
            }
            .badge(inbox.unreadCount)

            Tab(MainTab.profile.title, systemImage: MainTab.profile.symbol, value: MainTab.profile) {
                profileTab
            }
        }
    }

    private var profileTab: some View {
        NavigationStack(path: $profilePath) {
            ProfileView(
                profile: profile, onSignOut: onSignOut, avatarURL: profileAvatarURL,
                settings: profileSettings, documents: documentsActions
            )
        }
    }

    @ContentBuilder
    private var chat: some View {
        if let messageActions {
            NavigationStack(path: $chatPath) {
                InboxView(
                    model: inbox, patientID: profile.id, isActive: selection == .chat && chatPath.isEmpty,
                    actions: messageActions, loadDoctors: loadDoctors, onOpenPeer: openThread
                )
                .navigationDestination(for: MessagePeer.self) { peer in
                    ConversationView(
                        peer: peer, patientID: profile.id, actions: messageActions, onInboxChanged: refreshInbox
                    )
                }
            }
        } else {
            ContentUnavailableView("Messages Unavailable", systemImage: MainTab.chat.symbol)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeCanvas.ignoresSafeArea())
        }
    }

    private func homeDestination(_ route: HomeRoute) -> some View {
        Group {
            switch route {
            case .appointments(let presentation):
                MyAppointmentsView(
                    appointments: loadAppointments == nil ? demoAppointments : (presentation.map { [$0.appointment] } ?? []),
                    loadAppointments: loadAppointments, management: appointmentManagement, presenting: presentation
                )
            case .healthTracker:
                if let healthTrackerActions {
                    HealthTrackerView(actions: healthTrackerActions)
                }
            case .records:
                if let medicalRecordsActions {
                    MedicalRecordsView(actions: medicalRecordsActions, onFollowUp: openFollowUp, onChat: openChatAction)
                }
            case .documents:
                if let documentsActions {
                    DocumentsView(actions: documentsActions)
                }
            }
        }
        .toolbarVisibility(.visible, for: .navigationBar)
    }

    private var home: some View {
        let canOpenNotifications = loadNotifications != nil && markNotificationRead != nil

        return HomeView(
            patientName: profile.name,
            isActive: selection == .home && homePath.isEmpty,
            hasUnreadNotifications: notifications.hasUnread,
            loadAppointments: loadAppointments ?? { [] },
            onBook: { openDoctorSearch("") },
            onSearchDoctors: openDoctorSearch,
            onSeeAll: { openAppointments() },
            onOpenAppointment: { openAppointments(presenting: $0) },
            onOpenNotifications: canOpenNotifications ? { isNotificationsPresented = true } : nil,
            shortcuts: homeShortcuts,
            carePlanActions: carePlanActions
        )
        .sheet(isPresented: $isNotificationsPresented) {
            if let loadNotifications, let markNotificationRead {
                NavigationStack {
                    NotificationsView(
                        viewModel: notifications, loadNotifications: loadNotifications,
                        markNotificationRead: markNotificationRead
                    )
                }
                .tint(Color.themePrimary)
            }
        }
    }

    private var homeShortcuts: [HomeView.Shortcut] {
        var shortcuts = [
            HomeView.Shortcut(title: "Appointments", symbol: "calendar.badge.clock", action: { openAppointments() })
        ]
        if healthTrackerActions != nil {
            shortcuts.append(.init(
                title: "Health Tracker", symbol: "waveform.path.ecg", action: { homePath.append(HomeRoute.healthTracker) }
            ))
        }
        if medicalRecordsActions != nil {
            shortcuts.append(.init(
                title: "Records", symbol: "folder", action: { homePath.append(HomeRoute.records) }
            ))
        }
        if documentsActions != nil {
            shortcuts.append(.init(title: "Documents", symbol: "doc.text", action: { homePath.append(HomeRoute.documents) }))
        }
        return shortcuts
    }

    private func openDoctorSearch(_ query: String) {
        doctorPath.removeAll()
        doctorSearchRequest = DoctorListView.SearchRequest(query: query)
        selection = .doctors
    }

    private func openAppointments(presenting presentation: AppointmentPresentation? = nil) {
        homePath.append(HomeRoute.appointments(presentation))
    }

    private func openFollowUp(_ doctor: Doctor) {
        doctorPath = [.detail(doctor)]
        selection = .doctors
    }

    private var openChatAction: ((Doctor) -> Void)? {
        guard messageActions != nil else { return nil }
        return { doctor in
            if let peer = MessagePeer(doctor: doctor) { openThread(peer) }
        }
    }

    private func openThread(_ peer: MessagePeer) {
        guard peer.id != profile.id else { return }
        inbox.query = ""
        chatPath = [peer]
        selection = .chat
    }

    private func refreshInbox() async {
        if let messageActions {
            await inbox.load(using: messageActions.loadInbox)
        }
    }
}

#Preview {
    MainTabView(
        profile: UserProfile(
            id: MessagePeer.samplePatientID, name: "Demo Patient", email: "patient@example.test",
            role: "patient", patientNumber: "PS-DEMO"
        ),
        onSignOut: {},
        loadDoctors: { [.messageSample] + Doctor.samples.dropFirst() },
        appointmentManagement: .preview,
        loadNotifications: { [.sample] },
        markNotificationRead: { _ in },
        carePlanActions: .preview,
        healthTrackerActions: .preview,
        medicalRecordsActions: .preview,
        messageActions: .preview,
        documentsActions: .preview,
        profileSettings: .preview
    )
    .tint(Color.themePrimary)
}
