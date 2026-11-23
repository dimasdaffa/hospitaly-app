//
//  MyAppointmentsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct MyAppointmentsView: View {
    let appointments: [Appointment]

    @State private var showsHistory = false

    var body: some View {
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

            if visibleAppointments.isEmpty {
                ContentUnavailableView(
                    showsHistory ? "No appointment history" : "No upcoming appointments",
                    systemImage: "calendar"
                )
                .foregroundStyle(Color.themeSecondaryText)
            } else {
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
