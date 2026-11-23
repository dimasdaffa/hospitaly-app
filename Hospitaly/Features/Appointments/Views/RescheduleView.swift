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
        @Bindable var model = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Current Appointment")
                    .font(.headline)
                    .foregroundStyle(Color.themeText)
                AppointmentSummaryView(doctor: model.appointment.doctor, slot: model.appointment.slot)

                if let message = model.submissionError {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                }

                switch model.phase {
                case .loading:
                    ProgressView("Loading available times…")
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
                        .disabled(model.isSubmitting)
                    } else {
                        ContentUnavailableView(
                            "No Replacement Times", systemImage: "calendar",
                            description: Text("There are no other times available in the next 14 days.")
                        )
                    }
                }
            }
            .frame(maxWidth: 508)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if model.phase == .loaded && model.hasAvailableSlots {
                PrimaryActionButton(
                    title: model.isSubmitting ? "Saving…" : "Confirm New Time", action: confirm
                )
                .disabled(model.selectedSlot == nil || model.isSubmitting)
                .frame(maxWidth: 508)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.themeSurface, ignoresSafeAreaEdges: .bottom)
            }
        }
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Reschedule Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .disabled(model.isSubmitting)
            }
        }
        .interactiveDismissDisabled(model.isSubmitting)
        .task(id: model.loadAttempt) {
            await model.load(using: management.loadSlots)
        }
    }

    private func confirm() {
        Task {
            let attempt = viewModel.loadAttempt
            if let updated = await viewModel.submit(using: management.reschedule) {
                onUpdated(updated)
                dismiss()
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
