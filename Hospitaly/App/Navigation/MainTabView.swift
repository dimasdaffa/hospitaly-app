//
//  MainTabView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    private enum ShortcutSheet: String, Identifiable {
        case menu, healthTracker, records
        var id: Self { self }
    }

    @State private var selection: MainTab = .home
    @State private var doctorPath: [DoctorRoute] = []
    @State private var chatPath: [MessagePeer] = []
    @State private var shortcutSheet: ShortcutSheet?
    @State private var isNotificationsPresented = false
    @State private var notifications = NotificationsViewModel()
    @State private var inbox = InboxViewModel()

    let profile: UserProfile
    let onSignOut: @MainActor () throws -> Void
    let loadDoctors: @MainActor () async throws -> [Doctor]
    var loadDoctorDetails: (@MainActor (String, ClosedRange<Date>) async throws -> DoctorDetailData)? = nil
    var loadAppointments: (@MainActor () async throws -> [Appointment])? = nil
    var bookAppointment: (@MainActor (BookingRequest, Doctor) async throws -> Appointment)? = nil
    var appointmentManagement: AppointmentManagement? = nil
    var loadNotifications: (@MainActor () async throws -> [PatientNotification])? = nil
    var markNotificationRead: (@MainActor (UUID) async throws -> Void)? = nil
    var carePlanActions: CarePlanActions? = nil
    var healthTrackerActions: HealthTrackerActions? = nil
    var medicalRecordsActions: MedicalRecordsActions? = nil
    var messageActions: MessageActions? = nil

    var body: some View {
        tabs
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsTabBar {
                    MainTabBar(selection: $selection, hasUnreadMessages: inbox.hasUnread) {
                        shortcutSheet = .menu
                    }
                }
            }
            .sheet(item: $shortcutSheet, content: shortcutContent)
            .task(id: profile.id) { await refreshInbox() }
            .task(id: selection) {
                if selection == .home, let loadNotifications {
                    await notifications.load(using: loadNotifications)
                }
            }
    }

    private var showsTabBar: Bool {
        switch selection {
        case .doctors: doctorPath.isEmpty
        case .chat: chatPath.isEmpty
        default: true
        }
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            Tab(MainTab.home.title, systemImage: MainTab.home.symbol, value: MainTab.home) {
                home
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(MainTab.doctors.title, systemImage: MainTab.doctors.symbol, value: MainTab.doctors) {
                DoctorListView(
                    path: $doctorPath, loadDoctors: loadDoctors, loadDoctorDetails: loadDoctorDetails,
                    loadAppointments: loadAppointments, bookAppointment: bookAppointment,
                    appointmentManagement: appointmentManagement
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(MainTab.chat.title, systemImage: MainTab.chat.symbol, value: MainTab.chat) {
                chat
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(MainTab.profile.title, systemImage: MainTab.profile.symbol, value: MainTab.profile) {
                NavigationStack {
                    ProfileView(profile: profile, onSignOut: onSignOut)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
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

    @ViewBuilder
    private func shortcutContent(_ sheet: ShortcutSheet) -> some View {
        switch sheet {
        case .menu:
            QuickAccessSheet(
                onOpenTab: openTab,
                onOpenAppointments: openAppointmentsFromMenu,
                onOpenHealthTracker: openHealthTrackerAction,
                onOpenRecords: openRecordsAction,
                hasUnreadMessages: inbox.hasUnread
            )
        case .healthTracker:
            if let healthTrackerActions {
                NavigationStack {
                    HealthTrackerView(actions: healthTrackerActions)
                }
                .tint(Color.themePrimary)
            }
        case .records:
            if let medicalRecordsActions {
                NavigationStack {
                    MedicalRecordsView(actions: medicalRecordsActions, onFollowUp: openFollowUp, onChat: openChatAction)
                }
                .tint(Color.themePrimary)
            }
        }
    }

    private var openHealthTrackerAction: (@MainActor () -> Void)? {
        guard healthTrackerActions != nil else { return nil }
        return { shortcutSheet = .healthTracker }
    }

    private var openRecordsAction: (@MainActor () -> Void)? {
        guard medicalRecordsActions != nil else { return nil }
        return { shortcutSheet = .records }
    }

    private var home: some View {
        let canOpenNotifications = loadNotifications != nil && markNotificationRead != nil

        return HomeView(
            patientName: profile.name,
            isActive: selection == .home,
            hasUnreadNotifications: notifications.hasUnread,
            loadAppointments: loadAppointments ?? { [] },
            onBook: { openTab(.doctors) },
            onSeeAll: { openAppointments() },
            onOpenAppointment: { openAppointments(presenting: $0) },
            onOpenNotifications: canOpenNotifications ? { isNotificationsPresented = true } : nil,
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

    private func openTab(_ tab: MainTab) {
        if tab == .doctors {
            doctorPath.removeAll()
        }
        if tab == .chat {
            inbox.query = ""
            chatPath.removeAll()
        }

        selection = tab
        shortcutSheet = nil
    }

    private func openAppointmentsFromMenu() {
        shortcutSheet = nil
        openAppointments()
    }

    private func openAppointments(presenting presentation: AppointmentPresentation? = nil) {
        doctorPath = [.appointments(seed: presentation?.appointment, presenting: presentation)]
        selection = .doctors
    }

    private func openFollowUp(_ doctor: Doctor) {
        doctorPath = [.detail(doctor)]
        selection = .doctors
        shortcutSheet = nil
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
        shortcutSheet = nil
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
        messageActions: .preview
    )
}
