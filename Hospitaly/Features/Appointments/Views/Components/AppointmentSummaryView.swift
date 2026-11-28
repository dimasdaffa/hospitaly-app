//
//  AppointmentSummaryView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct AppointmentSummaryView: View {
    let doctor: Doctor
    let slot: AppointmentSlot
    let heading: LocalizedStringKey?
    let status: Appointment.Status?
    let referenceNumber: String?
    let showsDetailsLink: Bool

    init(doctor: Doctor, slot: AppointmentSlot) {
        self.doctor = doctor
        self.slot = slot
        heading = nil
        status = nil
        referenceNumber = nil
        showsDetailsLink = false
    }

    init(appointment: Appointment, heading: LocalizedStringKey? = nil, showsDetailsLink: Bool = false) {
        doctor = appointment.doctor
        slot = appointment.slot
        self.heading = heading
        status = appointment.status
        referenceNumber = appointment.referenceNumber
        self.showsDetailsLink = showsDetailsLink
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let heading {
                Text(heading)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeSurface.opacity(0.88))
            }

            HStack(spacing: 14) {
                DoctorAvatarView(doctor: doctor, size: 58, showsAvailability: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.title3.bold())
                        .foregroundStyle(Color.themeSurface)

                    if !doctor.specialty.isEmpty {
                        Text(doctor.specialty)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.themeSurface.opacity(0.88))
                    }
                }
            }

            visitFacts

            if showsDetailsLink {
                HStack {
                    Text("View Details")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeSurface)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            CrimsonHeaderBackdrop()
                .clipShape(.rect(cornerRadius: Theme.cardRadius))
                .shadow(color: Color.themeCrimsonDeep.opacity(0.20), radius: 10, y: 5)
        }
    }

    private var visitFacts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ClinicDate.label(slot.start, as: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                        .font(.headline)
                        .foregroundStyle(Color.themeText)
                    Text("\(slot.timeLabel) – \(ClinicDate.time(slot.end))")
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            } icon: {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.themeCrimsonInk)
                    .frame(width: 36, height: 36)
                    .background(Color.themeGlassRose, in: .rect(cornerRadius: 12))
            }

            if !doctor.hospital.isEmpty || !doctor.practiceLocation.isEmpty {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        if !doctor.hospital.isEmpty {
                            Text(doctor.hospital)
                                .fontWeight(.semibold)
                        }
                        if !doctor.practiceLocation.isEmpty {
                            Text(doctor.practiceLocation)
                        }
                    }
                } icon: {
                    Image(systemName: "mappin")
                        .foregroundStyle(Color.themeCrimsonInk)
                }
                .font(.footnote)
                .foregroundStyle(Color.themeSecondaryText)
            }

            if let status, let referenceNumber {
                Divider()
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        reference(referenceNumber)
                        Spacer(minLength: 0)
                        AppointmentStatusBadge(status: status)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        reference(referenceNumber)
                        AppointmentStatusBadge(status: status)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.themeSurface, in: .rect(cornerRadius: 16))
    }

    private func reference(_ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Reference")
                .font(.caption)
                .foregroundStyle(Color.themeSecondaryText)
            Text(value)
                .font(.footnote.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.themeText)
        }
    }
}

#Preview {
    AppointmentSummaryView(appointment: .sample, heading: "Next Appointment", showsDetailsLink: true)
        .padding()
        .background(Theme.roseCanvas)
}
