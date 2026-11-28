//
//  MyAppointmentsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct MyAppointmentsView: View {
    let loadAppointments: (@MainActor () async throws -> [Appointment])?
    let management: AppointmentManagement?

    @State private var viewModel: AppointmentsViewModel
    @State private var showsHistory = false
    @State private var change: AppointmentPresentation?

    init(
        appointments: [Appointment],
        loadAppointments: (@MainActor () async throws -> [Appointment])? = nil,
        management: AppointmentManagement? = nil,
        presenting: AppointmentPresentation? = nil
    ) {
        self.loadAppointments = loadAppointments
        self.management = management
        _change = State(initialValue: presenting)
        _viewModel = State(initialValue: AppointmentsViewModel(
            appointments: appointments, loadsFromAPI: loadAppointments != nil
        ))
    }

    var body: some View {
        let appointments = viewModel.appointments
        let upcoming = appointments.filter(\.isUpcoming).sorted { $0.slot.start < $1.slot.start }
        let history = appointments.filter { !$0.isUpcoming }.sorted { $0.slot.start > $1.slot.start }
        let visibleAppointments = showsHistory ? history : upcoming

        VStack(spacing: 14) {
            HStack(spacing: 4) {
                tab("Upcoming", selected: !showsHistory, count: upcoming.count) {
                    showsHistory = false
                }
                tab("History", selected: showsHistory) {
                    showsHistory = true
                }
            }
            .padding(4)
            .hospitalyGlassSurface(in: Capsule())
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView {
                LazyVStack(spacing: 14) {
                    listStatus(isEmpty: visibleAppointments.isEmpty)
                    ForEach(visibleAppointments) { appointment in
                        appointmentCard(appointment)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                if let loadAppointments { await viewModel.refresh(using: loadAppointments) }
            }
        }
        .frame(maxWidth: 540)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("My Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if loadAppointments != nil && viewModel.phase == .loaded {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh", systemImage: "arrow.clockwise", action: viewModel.reload)
                }
            }
        }
        .task(id: viewModel.loadAttempt) {
            if let loadAppointments {
                await viewModel.load(using: loadAppointments)
            }
        }
        .sheet(item: $change) { change in
            NavigationStack {
                switch change {
                case .details(let appointment):
                    appointmentDetails(appointment)
                case .reschedule(let appointment):
                    if let management {
                        RescheduleView(
                            appointment: appointment, management: management,
                            onUpdated: viewModel.apply, onRefresh: viewModel.reload
                        )
                    }
                case .cancel(let appointment):
                    if let management {
                        CancelAppointmentView(
                            appointment: appointment, submit: management.cancel,
                            onUpdated: viewModel.apply, onRefresh: viewModel.reload
                        )
                    }
                }
            }
            .tint(Color.themePrimary)
        }
    }

    @ViewBuilder
    private func listStatus(isEmpty: Bool) -> some View {
        switch viewModel.phase {
        case .loading:
            LoadingStateView(isEmpty ? "Loading appointments…" : "Refreshing appointments…")
                .padding(.vertical, isEmpty ? 32 : 6)
        case .failed(let message):
            if isEmpty {
                ContentUnavailableView {
                    Label("Couldn’t Load Appointments", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry", action: viewModel.reload)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                RefreshFailureView(message: message, onRetry: viewModel.reload)
            }
        case .loaded:
            if isEmpty {
                ContentUnavailableView(
                    showsHistory ? "No appointment history" : "No upcoming appointments",
                    systemImage: "calendar",
                    description: showsHistory
                        ? Text("Past, cancelled, and rejected appointments will appear here.")
                        : Text("Your upcoming appointments will appear here after you request a visit.")
                )
            }
        }
    }

    private func appointmentCard(_ appointment: Appointment) -> AppointmentCardView {
        let showsActions = canManage(appointment)
        return AppointmentCardView(
            appointment: appointment,
            onOpen: { change = .details(appointment) },
            onReschedule: showsActions ? { change = .reschedule(appointment) } : nil,
            onCancel: showsActions ? { change = .cancel(appointment) } : nil
        )
    }

    private func appointmentDetails(_ appointment: Appointment) -> AppointmentDetailView {
        let latest = viewModel.appointments.first { $0.id == appointment.id }
        let current = latest ?? appointment
        let showsActions = latest != nil && canManage(current)
        return AppointmentDetailView(
            appointment: current,
            onReschedule: showsActions ? { change = .reschedule(current) } : nil,
            onCancel: showsActions ? { change = .cancel(current) } : nil
        )
    }

    private func canManage(_ appointment: Appointment) -> Bool {
        management != nil && viewModel.phase == .loaded && appointment.canBeChanged
    }

    private func tab(
        _ title: LocalizedStringKey, selected: Bool, count: Int? = nil, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Text(title)

                if let count, count > 0 {
                    Text(count, format: .number)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selected ? Color.themeSurface : Color.themeCrimsonInk)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selected ? Color.themeSurface.opacity(0.19) : Color.themeGlassRose, in: Capsule())
                }
            }
            .font(.subheadline.weight(selected ? .semibold : .medium))
            .foregroundStyle(selected ? Color.themeSurface : Color.themeSecondaryText)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(selected ? Color.themeCrimsonInk : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Manage Appointments") {
    NavigationStack {
        MyAppointmentsView(appointments: [.sample] + Appointment.samples, management: .preview)
    }
}

#Preview("Empty Appointments") {
    NavigationStack {
        MyAppointmentsView(appointments: [])
    }
}

#Preview("Request Failed") {
    NavigationStack {
        MyAppointmentsView(appointments: [], loadAppointments: { throw APIError.connectionFailed })
    }
}
