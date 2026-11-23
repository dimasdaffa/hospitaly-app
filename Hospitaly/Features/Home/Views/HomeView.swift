//
//  HomeView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    let patientName: String
    let isActive: Bool
    let hasUnreadNotifications: Bool
    let loadAppointments: @MainActor () async throws -> [Appointment]
    let onBook: () -> Void
    let onSeeAll: () -> Void
    let onOpenAppointment: (AppointmentPresentation) -> Void
    let onOpenNotifications: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                bookingBanner
                nextAppointment
            }
            .frame(maxWidth: 540)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.themeCanvas.ignoresSafeArea())
        .task(id: isActive) {
            if isActive {
                await refresh()
            }
        }
        .refreshable { await refresh() }
    }

    private var header: some View {
        let words = patientName.split(whereSeparator: \.isWhitespace)
        let initials = words.prefix(2).compactMap(\.first).map { String($0) }.joined().uppercased()

        return HStack(spacing: 10) {
            Text(initials.isEmpty ? "P" : initials)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.themePrimary)
                .frame(width: 44, height: 44)
                .background(Color.themePrimary.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome Back,")
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
                Text(words.isEmpty ? "Patient" : patientName)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.themeText)
            }

            Spacer()

            if let onOpenNotifications {
                Button(action: onOpenNotifications) {
                    Label("Notifications", systemImage: "bell")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                        .foregroundStyle(Color.themeSecondaryText)
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .topTrailing) {
                            if hasUnreadNotifications {
                                Circle()
                                    .fill(Color.themePrimary)
                                    .frame(width: 7, height: 7)
                                    .padding(5)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bookingBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("RS Permata Sehat", systemImage: "cross.case")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.themeSurface.opacity(0.18), in: Capsule())

            Text("Your Health,\nOur Priority")
                .font(.title2.bold())

            Button(action: onBook) {
                Label("Book Now", systemImage: "arrow.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.themePrimary)
                    .padding(.horizontal, 15)
                    .frame(minHeight: 40)
                    .background(Color.themeSurface, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.themeSurface)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [.themePrimary, .themeDashboardHeroEnd],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.themePrimary.opacity(0.24), radius: 7, y: 6)
        }
    }

    private var nextAppointment: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next Appointment")
                    .font(.headline)
                    .foregroundStyle(Color.themeText)
                Spacer()
                Button("See All", action: onSeeAll)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.themePrimary)
                    .buttonStyle(.plain)
            }

            switch viewModel.phase {
            case .loading:
                ProgressView("Loading appointments…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            case .loaded(let appointment):
                if let appointment {
                    HomeAppointmentCardView(
                        appointment: appointment,
                        onDetails: { onOpenAppointment(.details(appointment)) },
                        onReschedule: appointment.canBeChanged ? { onOpenAppointment(.reschedule(appointment)) } : nil
                    )
                } else {
                    ContentUnavailableView {
                        Label("No Upcoming Appointments", systemImage: "calendar")
                    } description: {
                        Text("Book a visit to see your next appointment here.")
                    } actions: {
                        Button("Find a Doctor", action: onBook)
                            .buttonStyle(.borderedProminent)
                    }
                    .background(Color.themeSurface, in: .rect(cornerRadius: 20))
                }
            case .failed(let error):
                ContentUnavailableView {
                    Label("Couldn’t Load Appointments", systemImage: "exclamationmark.circle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry", action: retry)
                        .buttonStyle(.borderedProminent)
                }
                .background(Color.themeSurface, in: .rect(cornerRadius: 20))
            }
        }
    }

    private func retry() {
        Task { await refresh() }
    }

    private func refresh() async {
        await viewModel.loadNextAppointment(using: loadAppointments)
    }
}

#Preview("Next Appointment") {
    HomeView(
        patientName: "Demo Patient", isActive: true, hasUnreadNotifications: true,
        loadAppointments: { Appointment.samples },
        onBook: {}, onSeeAll: {}, onOpenAppointment: { _ in }, onOpenNotifications: {}
    )
    .tint(.themePrimary)
}

#Preview("No Upcoming Appointments") {
    HomeView(
        patientName: "Demo Patient", isActive: true, hasUnreadNotifications: false,
        loadAppointments: { [] },
        onBook: {}, onSeeAll: {}, onOpenAppointment: { _ in }, onOpenNotifications: {}
    )
    .tint(.themePrimary)
}

#Preview("Couldn’t Load Appointments") {
    HomeView(
        patientName: "Demo Patient", isActive: true, hasUnreadNotifications: false,
        loadAppointments: { throw APIError.connectionFailed },
        onBook: {}, onSeeAll: {}, onOpenAppointment: { _ in }, onOpenNotifications: {}
    )
    .tint(.themePrimary)
}
