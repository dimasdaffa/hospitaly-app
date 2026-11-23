//
//  HomeAppointmentCardView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct HomeAppointmentCardView: View {
    let appointment: Appointment
    let onDetails: () -> Void
    let onReschedule: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                DoctorAvatarView(doctor: appointment.doctor, size: 58, showsAvailability: false)

                VStack(alignment: .leading, spacing: 5) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    if !appointment.doctor.specialty.isEmpty {
                        Text(appointment.doctor.specialty)
                            .font(.caption)
                            .foregroundStyle(Color.themeSecondaryText)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            dateLabel
                            timeLabel
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            dateLabel
                            timeLabel
                        }
                    }
                    .padding(.top, 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AppointmentStatusBadge(status: appointment.status)
            }

            Divider()

            HStack(spacing: 10) {
                if let onReschedule {
                    Button(action: onReschedule) {
                        Text("Reschedule")
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(Color.themeSecondaryText)
                            .background(Color.themeSurface, in: Capsule())
                            .overlay { Capsule().strokeBorder(Color.themeOutline, lineWidth: 1) }
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onDetails) {
                    Text("Details")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(Color.themePrimary)
                        .background(Color.themePrimary.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(16)
        .background(Color.themeSurface, in: .rect(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(Color.themeCardBorder, lineWidth: 1) }
        .shadow(color: Color.themeCardShadow.opacity(0.35), radius: 2, y: 1)
    }

    private var dateLabel: some View {
        scheduleLabel(ClinicDate.label(appointment.slot.start, as: .dateTime.month(.abbreviated).day()), icon: "calendar")
    }

    private var timeLabel: some View {
        scheduleLabel(appointment.slot.timeLabel, icon: "clock")
    }

    private func scheduleLabel(_ value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(Color.themePrimary)
            Text(value)
                .foregroundStyle(Color.themeSecondaryText)
        }
        .font(.caption2.weight(.medium))
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(Color.themeCanvas, in: Capsule())
    }
}

#Preview {
    HomeAppointmentCardView(appointment: .sample, onDetails: {}, onReschedule: {})
        .padding()
        .background(Color.themeCanvas)
}
