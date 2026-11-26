//
//  CancellationSubmittedView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct CancellationSubmittedView: View {
    let appointment: Appointment
    let onReturn: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.themePrimary)
                    .frame(width: 84, height: 84)
                    .hospitalyGlassSurface(in: Circle())

                Text("Cancellation Request Submitted")
                    .font(.title2.bold())
                    .foregroundStyle(Color.themeText)

                Text("Your request is pending hospital approval.")
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)

                AppointmentSummaryView(doctor: appointment.doctor, slot: appointment.slot)
                AppointmentStatusBadge(status: appointment.status)

                PrimaryActionButton(title: "Return to Appointments", action: onReturn)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 508)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    let sample = Appointment.sample

    CancellationSubmittedView(
        appointment: Appointment(
            id: sample.id, doctor: sample.doctor, slot: sample.slot,
            reason: sample.reason, complaints: sample.complaints,
            status: .cancellationRequested, referenceNumber: sample.referenceNumber
        ),
        onReturn: {}
    )
}
