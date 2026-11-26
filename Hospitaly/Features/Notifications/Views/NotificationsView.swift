//
//  NotificationsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: NotificationsViewModel
    let loadNotifications: @MainActor () async throws -> [PatientNotification]
    let markNotificationRead: @MainActor (UUID) async throws -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                stateContent

                if let error = viewModel.readError {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                LazyVStack(spacing: 12) {
                    ForEach(viewModel.notifications) { notification in
                        row(notification)
                    }
                }
            }
            .frame(maxWidth: 540)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh", systemImage: "arrow.clockwise", action: reload)
                    .disabled(viewModel.phase == .loading || viewModel.markingReadID != nil)
            }
        }
        .task { await viewModel.load(using: loadNotifications) }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.phase {
        case .idle, .loading:
            if viewModel.notifications.isEmpty {
                ProgressView("Loading notifications…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        case .loaded:
            if viewModel.notifications.isEmpty {
                ContentUnavailableView(
                    "No Notifications", systemImage: "bell",
                    description: Text("Appointment approvals and cancellation updates will appear here.")
                )
            }
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn’t Load Notifications", systemImage: "exclamationmark.circle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry", action: reload)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.markingReadID != nil)
            }
        }
    }

    private func row(_ notification: PatientNotification) -> some View {
        let display = presentation(for: notification.type)

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: display.symbol)
                .foregroundStyle(Color.themePrimary)
                .frame(width: 42, height: 42)
                .background(Color.themePrimary.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(display.title)
                    .font(.headline)
                    .foregroundStyle(Color.themeText)

                Text(display.message)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)

                Text("REF-\(notification.appointmentId.uuidString)")
                    .font(.caption)
                    .foregroundStyle(Color.themeMutedText)

                if let createdAt = notification.createdAt {
                    Text(ClinicDate.label(createdAt, as: .dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.caption)
                        .foregroundStyle(Color.themeMutedText)
                }

                if notification.isUnread {
                    Button(viewModel.markingReadID == notification.id ? "Marking as read…" : "Mark as read") {
                        Task { await viewModel.markRead(notification.id, using: markNotificationRead) }
                    }
                    .font(.caption.weight(.semibold))
                    .disabled(viewModel.phase == .loading || viewModel.markingReadID != nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if notification.isUnread {
                Circle()
                    .fill(Color.themePrimary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 7)
            }
        }
        .padding(16)
        .hospitalyPanel()
    }

    private func presentation(for type: String) -> (title: LocalizedStringKey, message: LocalizedStringKey, symbol: String) {
        switch type {
        case "approved":
            ("Appointment approved", "Your visit is confirmed. You can check the time in My Appointments.", "checkmark.circle")
        case "rejected":
            ("Appointment declined", "Open My Appointments to review the request status.", "xmark.circle")
        case "cancelled":
            ("Appointment cancelled", "The hospital approved your cancellation request.", "calendar.badge.minus")
        case "cancellation_declined":
            ("Cancellation declined", "Check My Appointments for the current visit status.", "exclamationmark.circle")
        default:
            ("Appointment update", "Open My Appointments for the current status.", "bell")
        }
    }

    private func reload() {
        Task { await viewModel.load(using: loadNotifications) }
    }
}

#Preview("Unread Notification") {
    NavigationStack {
        NotificationsView(
            viewModel: NotificationsViewModel(),
            loadNotifications: { [.sample] },
            markNotificationRead: { _ in }
        )
    }
}

#Preview("Empty Notifications") {
    NavigationStack {
        NotificationsView(
            viewModel: NotificationsViewModel(),
            loadNotifications: { [] },
            markNotificationRead: { _ in }
        )
    }
}

#Preview("Request Failed") {
    NavigationStack {
        NotificationsView(
            viewModel: NotificationsViewModel(),
            loadNotifications: { throw APIError.connectionFailed },
            markNotificationRead: { _ in }
        )
    }
}
