//
//  AppointmentCardView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct AppointmentCardView: View {
    let appointment: Appointment
    let onOpen: () -> Void
    var isFeatured = false

    var body: some View {
        if isFeatured {
            Button(action: onOpen) {
                AppointmentSummaryView(appointment: appointment, heading: "Next Appointment", showsDetailsLink: true)
                    .contentShape(.rect(cornerRadius: Theme.cardRadius))
            }
            .buttonStyle(.plain)
        } else {
            timelineCard
        }
    }

    private var timelineCard: some View {
        Button(action: onOpen) {
            detailsLabel
                .padding(16)
                .hospitalyPanel()
                .contentShape(.rect(cornerRadius: Theme.cardRadius))
        }
        .buttonStyle(.plain)
    }

    private var detailsLabel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                dateTile

                VStack(alignment: .leading, spacing: 5) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    if !appointment.doctor.specialty.isEmpty {
                        Text(appointment.doctor.specialty)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.themeCrimsonInk)
                    }

                    Label(appointment.slot.timeLabel, systemImage: "clock")
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                DoctorAvatarView(doctor: appointment.doctor, size: 44, showsAvailability: false)
            }

            Text(appointment.reason)
                .font(.subheadline)
                .foregroundStyle(Color.themeText)

            HStack(alignment: .center, spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        AppointmentStatusBadge(status: appointment.status)
                        Text(appointment.referenceNumber)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        AppointmentStatusBadge(status: appointment.status)
                        Text(appointment.referenceNumber)
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.themeSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.themeCrimsonInk)
            }
        }
    }

    private var dateTile: some View {
        VStack(spacing: 2) {
            Text(ClinicDate.label(appointment.slot.start, as: .dateTime.day()))
                .font(.title2.bold())
                .monospacedDigit()
            Text(ClinicDate.label(appointment.slot.start, as: .dateTime.month(.abbreviated).year(.twoDigits)))
                .font(.caption)
        }
        .foregroundStyle(Color.themeCrimsonInk)
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .frame(minWidth: 56)
        .background(Color.themeGlassRose.opacity(0.72), in: .rect(cornerRadius: 14))
    }
}

#Preview {
    AppointmentCardView(appointment: .sample, onOpen: {})
        .padding()
        .background(Theme.roseCanvas)
}

#Preview("Next Appointment") {
    AppointmentCardView(appointment: .sample, onOpen: {}, isFeatured: true)
        .padding()
        .background(Theme.roseCanvas)
}
