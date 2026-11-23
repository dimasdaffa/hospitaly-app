//
//  MainTabView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @State private var selection: MainTab = .profile
    @State private var doctorPath: [DoctorRoute] = []
    @State private var isQuickAccessPresented = false
    @State private var isNotificationsPresented = false
    @State private var notifications = NotificationsViewModel()

    let profile: UserProfile
    let onSignOut: @MainActor () throws -> Void
    let loadDoctors: @MainActor () async throws -> [Doctor]
    var loadDoctorDetails: (@MainActor (String, ClosedRange<Date>) async throws -> DoctorDetailData)? = nil
    var loadAppointments: (@MainActor () async throws -> [Appointment])? = nil
    var bookAppointment: (@MainActor (BookingRequest, Doctor) async throws -> Appointment)? = nil
    var appointmentManagement: AppointmentManagement? = nil
    var loadNotifications: (@MainActor () async throws -> [PatientNotification])? = nil
    var markNotificationRead: (@MainActor (UUID) async throws -> Void)? = nil

    var body: some View {
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
                placeholder(.chat, message: "Patient messages are coming soon.")
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(MainTab.profile.title, systemImage: MainTab.profile.symbol, value: MainTab.profile) {
                NavigationStack {
                    ProfileView(profile: profile, onSignOut: onSignOut)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selection != .doctors || doctorPath.isEmpty {
                MainTabBar(selection: $selection) {
                    isQuickAccessPresented = true
                }
            }
        }
        .sheet(isPresented: $isQuickAccessPresented) {
            QuickAccessSheet(
                onOpenTab: openTabFromMenu,
                onOpenAppointments: openAppointmentsFromMenu
            )
        }
        .task(id: selection) {
            if selection == .home, let loadNotifications {
                await notifications.load(using: loadNotifications)
            }
        }
    }

    private var home: some View {
        NavigationStack {
            ContentUnavailableView("Dashboard Coming Soon", systemImage: "house")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeCanvas.ignoresSafeArea())
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if loadNotifications != nil, markNotificationRead != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isNotificationsPresented = true
                            } label: {
                                Label("Notifications", systemImage: "bell")
                                    .labelStyle(.iconOnly)
                                    .overlay(alignment: .topTrailing) {
                                        if notifications.hasUnread {
                                            Circle()
                                                .fill(Color.themePrimary)
                                                .frame(width: 7, height: 7)
                                        }
                                    }
                            }
                        }
                    }
                }
        }
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

    private func placeholder(_ tab: MainTab, message: LocalizedStringKey) -> some View {
        ContentUnavailableView(tab.title, systemImage: tab.symbol, description: Text(message))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeCanvas.ignoresSafeArea())
    }

    private func openTabFromMenu(_ tab: MainTab) {
        if tab == .doctors {
            doctorPath.removeAll()
        }

        selection = tab
        isQuickAccessPresented = false
    }

    private func openAppointmentsFromMenu() {
        doctorPath = [.appointments(confirmed: nil)]
        selection = .doctors
        isQuickAccessPresented = false
    }
}

#Preview {
    MainTabView(
        profile: UserProfile(
            id: UUID(), name: "Demo Patient", email: "patient@example.test",
            role: "patient", patientNumber: "PS-DEMO"
        ),
        onSignOut: {},
        loadDoctors: { Doctor.samples },
        appointmentManagement: .preview,
        loadNotifications: { [.sample] },
        markNotificationRead: { _ in }
    )
}
