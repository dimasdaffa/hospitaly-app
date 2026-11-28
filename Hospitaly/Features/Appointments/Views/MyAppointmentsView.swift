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
        let nextAppointment = showsHistory ? nil : upcoming.first { $0.slot.start > .now }

        VStack(spacing: 18) {
            Picker("Appointment List", selection: $showsHistory) {
                Text(upcoming.isEmpty ? "Upcoming" : "Upcoming (\(upcoming.count))")
                    .tag(false)
                Text("History").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.contentInset)
            .padding(.top, 12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    listStatus(isEmpty: visibleAppointments.isEmpty)

                    if let nextAppointment {
                        appointmentCard(nextAppointment, isFeatured: true)

                        if visibleAppointments.count > 1 {
                            Text("Other Appointments")
                                .font(.headline)
                                .foregroundStyle(Color.themeText)
                                .padding(.top, 6)
                        }
                    }

                    ForEach(visibleAppointments.filter { $0.id != nextAppointment?.id }) { appointment in
                        appointmentCard(appointment)
                    }
                }
                .padding(.horizontal, Theme.contentInset)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                if let loadAppointments { await viewModel.refresh(using: loadAppointments) }
            }
        }
        .frame(maxWidth: Theme.dashboardWidth)
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
                .frame(maxWidth: .infinity)
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

    private func appointmentCard(_ appointment: Appointment, isFeatured: Bool = false) -> AppointmentCardView {
        let showsActions = canManage(appointment)
        return AppointmentCardView(
            appointment: appointment,
            onOpen: { change = .details(appointment) },
            isFeatured: isFeatured,
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
