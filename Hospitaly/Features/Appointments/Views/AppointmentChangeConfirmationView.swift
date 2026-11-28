//
//  AppointmentChangeConfirmationView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 28/11/26.
//

import SwiftUI

struct AppointmentChangeConfirmationView: View {
    enum Change: Equatable {
        case reschedule, cancellation
    }

    let appointment: Appointment
    let change: Change
    let onReturn: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                resultHeading
                AppointmentSummaryView(appointment: appointment)
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: "Return to Appointments", icon: "arrow.right", action: onReturn)
                .padding(.horizontal, Theme.contentInset)
                .padding(.vertical, 10)
                .frame(maxWidth: Theme.dashboardWidth)
                .frame(maxWidth: .infinity)
                .hospitalyActionBar()
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
    }

    private var resultHeading: some View {
        Label {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(Color.themeText)

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
        } icon: {
            Image(systemName: change == .reschedule ? "calendar.badge.clock" : "calendar.badge.minus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.themeCrimsonInk)
                .frame(width: 48, height: 48)
                .background(Color.themeGlassRose, in: .rect(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private var title: LocalizedStringKey {
        switch change {
        case .reschedule:
            appointment.status == .pending ? "Reschedule Request Submitted" : "Appointment Updated"
        case .cancellation:
            appointment.status == .cancelled ? "Appointment Cancelled" : "Cancellation Request Submitted"
        }
    }

    private var message: LocalizedStringKey? {
        switch (change, appointment.status) {
        case (.reschedule, .pending): "The new time is pending hospital approval."
        case (.cancellation, .cancellationRequested): "The hospital is reviewing your request."
        default: nil
        }
    }
}

#Preview("Cancellation Pending") {
    let sample = Appointment.sample

    AppointmentChangeConfirmationView(
        appointment: Appointment(
            id: sample.id, doctor: sample.doctor, slot: sample.slot,
            reason: sample.reason, complaints: sample.complaints,
            status: .cancellationRequested, referenceNumber: sample.referenceNumber
        ),
        change: .cancellation,
        onReturn: {}
    )
}

#Preview("Reschedule Pending") {
    AppointmentChangeConfirmationView(appointment: .sample, change: .reschedule, onReturn: {})
}
