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
                AppointmentSummaryView(appointment: appointment)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Reason for Visit")
                        .font(.title3.bold())
                        .foregroundStyle(Color.themeText)
                    Text(appointment.reason)
                        .font(.subheadline)
                        .foregroundStyle(Color.themeText)

                    if !appointment.complaints.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Complaints")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.themeSecondaryText)
                            Text(appointment.complaints)
                                .font(.subheadline)
                                .foregroundStyle(Color.themeText)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))

                if appointment.status == .cancellationRequested {
                    Label("The hospital is reviewing your cancellation request.", systemImage: "clock")
                        .font(.footnote)
                        .foregroundStyle(Color.themePendingText)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.themePendingBackground, in: .rect(cornerRadius: 16))
                }
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var actionBar: some View {
        if onReschedule != nil || onCancel != nil {
            VStack(spacing: 8) {
                if let onReschedule {
                    PrimaryActionButton(title: "Reschedule", icon: "calendar.badge.clock", action: onReschedule)
                }

                if let onCancel {
                    Button(role: .destructive, action: onCancel) {
                        Text(appointment.status == .pending ? "Cancel Request" : "Cancel Appointment")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.themeCrimsonInk)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 16))
                            .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Color.themeGlassRose) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.contentInset)
            .padding(.vertical, 10)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
            .hospitalyActionBar()
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
