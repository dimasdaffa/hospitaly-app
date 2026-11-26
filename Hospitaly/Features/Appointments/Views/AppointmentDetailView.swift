//
//  AppointmentDetailView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    let onReschedule: (() -> Void)?
    let onCancel: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppointmentSummaryView(doctor: appointment.doctor, slot: appointment.slot)

                VStack(alignment: .leading, spacing: 12) {
                    AppointmentStatusBadge(status: appointment.status)
                    field("Reference", value: appointment.referenceNumber)
                    field("Reason for Visit", value: appointment.reason)

                    if !appointment.complaints.isEmpty {
                        field("Complaints", value: appointment.complaints)
                    }

                    if appointment.status == .cancellationRequested {
                        Text("The hospital is reviewing your cancellation request.")
                            .font(.footnote)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .hospitalyPanel(cornerRadius: 18)

                if let onReschedule, let onCancel {
                    PrimaryActionButton(title: "Reschedule", icon: "calendar", action: onReschedule)
                    Button(role: .destructive, action: onCancel) {
                        Text(appointment.status == .pending ? "Cancel Request" : "Cancel Appointment")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.themePrimary)
                    .hospitalyPanel(cornerRadius: 18)
                }
            }
            .frame(maxWidth: 508)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private func field(_ label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.themeSecondaryText)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.themeText)
        }
    }
}

#Preview("Upcoming Appointment") {
    NavigationStack {
        AppointmentDetailView(appointment: .sample, onReschedule: {}, onCancel: {})
    }
}

#Preview("Past Appointment") {
    if let appointment = Appointment.samples.last {
        NavigationStack {
            AppointmentDetailView(appointment: appointment, onReschedule: nil, onCancel: nil)
        }
    }
}
