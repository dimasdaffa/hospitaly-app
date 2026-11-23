//
//  MyAppointmentsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct MyAppointmentsView: View {
    let loadAppointments: (@MainActor () async throws -> [Appointment])?

    @State private var viewModel: AppointmentsViewModel
    @State private var showsHistory = false

    init(
        appointments: [Appointment],
        loadAppointments: (@MainActor () async throws -> [Appointment])? = nil
    ) {
        self.loadAppointments = loadAppointments
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
            .background(Color.themeOutline, in: Capsule())
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if case .failed(let message) = viewModel.phase {
                ContentUnavailableView {
                    Label("Couldn’t Load Appointments", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry", action: viewModel.reload)
                        .buttonStyle(.borderedProminent)
                }
            }

            if viewModel.phase == .loading && visibleAppointments.isEmpty {
                ProgressView("Loading appointments…")
                    .padding(.vertical, 32)
            } else if visibleAppointments.isEmpty && viewModel.phase == .loaded {
                ContentUnavailableView(
                    showsHistory ? "No appointment history" : "No upcoming appointments",
                    systemImage: "calendar",
                    description: showsHistory
                        ? Text("Past, cancelled, and rejected appointments will appear here.")
                        : Text("Your upcoming appointments will appear here after you request a visit.")
                )
                .foregroundStyle(Color.themeSecondaryText)
            } else if !visibleAppointments.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(visibleAppointments) { appointment in
                            AppointmentCardView(appointment: appointment)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: 540)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.themeCanvas.ignoresSafeArea())
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
                        .foregroundStyle(Color.themePrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.themePrimary.opacity(0.09), in: Capsule())
                }
            }
            .font(.subheadline.weight(selected ? .semibold : .medium))
            .foregroundStyle(selected ? Color.themePrimary : Color.themeSecondaryText)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(selected ? Color.themeSurface : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MyAppointmentsView(appointments: [.sample] + Appointment.samples)
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
