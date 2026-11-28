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
            LazyVStack(alignment: .leading, spacing: 14) {
                summary
                stateContent

                ForEach(viewModel.notifications) { notification in
                    row(notification)
                }
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await viewModel.load(using: loadNotifications) }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let error = viewModel.readError {
                markReadError(error)
            }
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

    private var summary: some View {
        let unread = viewModel.notifications.filter(\.isUnread).count

        return VStack(alignment: .leading, spacing: 8) {
            Label("Appointment Updates", systemImage: "bell")
                .font(.title2.bold())

            if !viewModel.notifications.isEmpty {
                Text("\(unread) unread")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.themeSurface.opacity(0.16), in: Capsule())
            }
        }
        .foregroundStyle(Color.themeSurface)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            CrimsonHeaderBackdrop()
                .clipShape(.rect(cornerRadius: Theme.cardRadius))
        }
    }

    private func markReadError(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Couldn’t Mark as Read", systemImage: "exclamationmark.circle.fill")
                .fontWeight(.semibold)
            Text(message)
        }
        .font(.footnote)
        .foregroundStyle(Color.themeCrimsonInk)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeGlassRose, in: .rect(cornerRadius: 14))
        .padding(.horizontal, Theme.contentInset)
        .padding(.top, 8)
        .frame(maxWidth: Theme.dashboardWidth)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.phase {
        case .idle, .loading:
            LoadingStateView(viewModel.notifications.isEmpty ? "Loading notifications…" : "Refreshing notifications…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, viewModel.notifications.isEmpty ? 40 : 6)
        case .loaded:
            if viewModel.notifications.isEmpty {
                ContentUnavailableView(
                    "No Notifications", systemImage: "bell",
                    description: Text("Appointment approvals and cancellation updates will appear here.")
                )
            }
        case .failed(let message):
            if !viewModel.notifications.isEmpty {
                RefreshFailureView(message: message, onRetry: reload)
                    .disabled(viewModel.markingReadID != nil)
            } else {
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
    }

    private func row(_ notification: PatientNotification) -> some View {
        let display = presentation(for: notification.type)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: display.symbol)
                    .font(.headline)
                    .foregroundStyle(display.accent)
                    .frame(width: 44, height: 44)
                    .background(display.accent.opacity(0.10), in: .rect(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(display.title)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    if let date = notification.createdAt {
                        Text(ClinicDate.label(date, as: .dateTime.month(.abbreviated).day().year().hour().minute()))
                            .font(.caption)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if notification.isUnread {
                    Text("Unread")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.themeCrimsonInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.themeGlassRose, in: Capsule())
                }
            }

            Text(display.message)
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondaryText)

            if notification.isUnread {
                Button {
                    Task { await viewModel.markRead(notification.id, using: markNotificationRead) }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.markingReadID == notification.id {
                            ProgressView()
                            Text("Marking as read…")
                        } else {
                            Image(systemName: "checkmark")
                            Text("Mark as read")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .tint(Color.themeCrimsonInk)
                .disabled(viewModel.phase == .loading || viewModel.markingReadID != nil)
            }

            Divider()

            DisclosureGroup {
                Text("REF-\(notification.appointmentId.uuidString)")
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.themeSecondaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
            } label: {
                Text("Appointment Reference")
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .tint(Color.themeCrimsonInk)
        }
        .padding(16)
        .hospitalyPanel()
        .overlay {
            if notification.isUnread {
                RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .strokeBorder(Color.themeGlassRose)
                    .allowsHitTesting(false)
            }
        }
    }

    private func presentation(
        for type: String
    ) -> (title: LocalizedStringKey, message: LocalizedStringKey, symbol: String, accent: Color) {
        switch type {
        case "approved":
            ("Appointment approved", "Your visit is confirmed. Check the time in My Appointments.", "checkmark.circle", .themeAvailableText)
        case "rejected":
            ("Appointment declined", "Open My Appointments to review the request status.", "xmark.circle", .themeCrimsonInk)
        case "cancelled":
            ("Appointment cancelled", "The hospital approved your cancellation request.", "calendar.badge.minus", .themeCrimsonInk)
        case "cancellation_declined":
            ("Cancellation declined", "The hospital declined your cancellation request. Check your visit status in My Appointments.", "exclamationmark.circle", .themePendingText)
        default:
            ("Appointment update", "Open My Appointments for the current status.", "bell", .themeSecondaryText)
        }
    }

    private func reload() {
        Task { await viewModel.load(using: loadNotifications) }
    }
}

#Preview("Appointment Updates") {
    @Previewable @State var viewModel = NotificationsViewModel()
    @Previewable @State var updates: [PatientNotification] = [
        .sample,
        PatientNotification(
            id: UUID(), appointmentId: UUID(), type: "cancellation_declined",
            createdAt: .now.addingTimeInterval(-3_600), readAt: nil
        ),
        PatientNotification(
            id: UUID(), appointmentId: UUID(), type: "cancelled",
            createdAt: .now.addingTimeInterval(-86_400), readAt: .now
        )
    ]

    NavigationStack {
        NotificationsView(
            viewModel: viewModel,
            loadNotifications: { updates },
            markNotificationRead: { id in
                if let index = updates.firstIndex(where: { $0.id == id }) {
                    updates[index].readAt = .now
                }
            }
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
