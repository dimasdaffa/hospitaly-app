//
//  AppointmentCardView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct AppointmentCardView: View {
    let appointment: Appointment
    let onOpen: () -> Void
    var onReschedule: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpen) {
                detailsLabel
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let onReschedule, let onCancel {
                Divider()

                HStack {
                    Button("Reschedule", systemImage: "calendar", action: onReschedule)
                        .foregroundStyle(Color.themeSecondaryText)
                    Spacer(minLength: 8)
                    Button(
                        appointment.status == .pending ? "Cancel Request" : "Cancel Appointment",
                        systemImage: "xmark.circle", action: onCancel
                    )
                    .foregroundStyle(Color.themePrimary)
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.themeSurface, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.themeCardBorder, lineWidth: 1)
        }
        .shadow(color: Color.themeCardShadow.opacity(0.5), radius: 2, y: 1)
    }

    private var detailsLabel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                DoctorAvatarView(doctor: appointment.doctor, size: 54, showsAvailability: false)

                VStack(alignment: .leading, spacing: 5) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    if !appointment.doctor.specialty.isEmpty {
                        Text(appointment.doctor.specialty)
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(Color.themePrimary)
                    }

                    Label("\(appointment.slot.dateLabel) · \(appointment.slot.timeLabel)", systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AppointmentStatusBadge(status: appointment.status)
            }

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.reason)
                        .font(.subheadline)
                        .foregroundStyle(Color.themeText)

                    Text(appointment.referenceNumber)
                        .font(.caption)
                        .foregroundStyle(Color.themeMutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.themeMutedText)
            }
        }
    }
}

#Preview {
    AppointmentCardView(appointment: .sample, onOpen: {})
        .padding()
        .background(Color.themeCanvas)
}
