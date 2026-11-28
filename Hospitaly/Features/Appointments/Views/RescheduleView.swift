//
//  RescheduleView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct RescheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RescheduleViewModel
    @State private var submitted: Appointment?

    let management: AppointmentManagement
    let onUpdated: (Appointment) -> Void
    let onRefresh: () -> Void

    init(
        appointment: Appointment, management: AppointmentManagement,
        onUpdated: @escaping (Appointment) -> Void, onRefresh: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: RescheduleViewModel(appointment: appointment))
        self.management = management
        self.onUpdated = onUpdated
        self.onRefresh = onRefresh
    }

    var body: some View {
        Group {
            if let submitted {
                AppointmentChangeConfirmationView(appointment: submitted, change: .reschedule) { dismiss() }
            } else {
                form
            }
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle(submitted == nil ? "Reschedule Appointment" : "Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .disabled(viewModel.isSubmitting)
            }
        }
        .interactiveDismissDisabled(viewModel.isSubmitting)
        .task(id: viewModel.loadAttempt) {
            await viewModel.load(using: management.loadSlots)
        }
    }

    private var form: some View {
        @Bindable var model = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppointmentSummaryView(appointment: model.appointment, heading: "Current Appointment")

                if let message = model.submissionError {
                    Label(message, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(Color.themeCrimsonInk)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.themeGlassRose, in: .rect(cornerRadius: 14))
                }

                switch model.phase {
                case .loading:
                    LoadingStateView("Loading available times…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn’t Load Times", systemImage: "exclamationmark.circle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry", action: model.reload)
                            .buttonStyle(.borderedProminent)
                    }
                case .loaded:
                    if model.hasAvailableSlots {
                        AppointmentSlotPicker(
                            days: model.days, dateRange: model.dateRange, selectedDate: $model.selectedDate,
                            slots: model.slotsForSelectedDate, selectedSlot: model.selectedSlot,
                            onSelectSlot: model.selectSlot
                        )
                        .padding(16)
                        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                        .disabled(model.isSubmitting)
                    } else {
                        ContentUnavailableView(
                            "No Replacement Times", systemImage: "calendar",
                            description: Text("There are no other times available in the next 14 days.")
                        )
                    }
                }
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.phase == .loaded && model.hasAvailableSlots {
                VStack(alignment: .leading, spacing: 10) {
                    if let slot = model.selectedSlot {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("New Time")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.themeCrimsonInk)
                            Text("\(slot.dateLabel) · \(slot.timeLabel)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.themeText)
                        }
                    }

                    PrimaryActionButton(
                        title: model.isSubmitting ? "Saving…" : "Confirm New Time", icon: "arrow.right",
                        isLoading: model.isSubmitting, action: confirm
                    )
                    .disabled(model.selectedSlot == nil || model.isSubmitting)
                }
                .padding(.horizontal, Theme.contentInset)
                .padding(.vertical, 10)
                .frame(maxWidth: Theme.dashboardWidth)
                .frame(maxWidth: .infinity)
                .hospitalyActionBar()
            }
        }
    }

    private func confirm() {
        Task {
            let attempt = viewModel.loadAttempt
            if let updated = await viewModel.submit(using: management.reschedule) {
                onUpdated(updated)
                submitted = updated
            } else if viewModel.loadAttempt != attempt {
                onRefresh()
            }
        }
    }
}

#Preview("No Replacement Times") {
    NavigationStack {
        RescheduleView(
            appointment: .sample,
            management: AppointmentManagement(
                loadSlots: { _, _ in [] },
                reschedule: { appointment, _ in appointment },
                cancel: { appointment, _ in appointment }
            ),
            onUpdated: { _ in }, onRefresh: {}
        )
    }
}

#Preview("Replacement Times") {
    NavigationStack {
        RescheduleView(
            appointment: .sample,
            management: AppointmentManagement(
                loadSlots: { _, _ in [.sample(dayOffset: 2)] },
                reschedule: { _, _ in throw APIError.httpStatus(409) },
                cancel: { _, _ in throw APIError.connectionFailed }
            ),
            onUpdated: { _ in }, onRefresh: {}
        )
    }
}
