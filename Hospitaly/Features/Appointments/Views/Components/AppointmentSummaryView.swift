//
//  AppointmentSummaryView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct AppointmentSummaryView: View {
    let doctor: Doctor
    let slot: AppointmentSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                DoctorAvatarView(doctor: doctor, size: 54, showsAvailability: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeSurface)

                    Text(doctor.specialty)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeSurface.opacity(0.88))

                    Label(doctor.hospital, systemImage: "mappin")
                        .font(.footnote)
                        .foregroundStyle(Color.themeSurface.opacity(0.82))
                }
            }

            Rectangle().fill(Color.themeSurface.opacity(0.24)).frame(height: 1)

            HStack(spacing: 16) {
                detail("DATE", value: slot.dateLabel, icon: "calendar")
                detail("TIME", value: slot.timeLabel, icon: "clock")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .fill(Theme.crimsonGradient)
                .shadow(color: Color.themeCrimsonDeep.opacity(0.20), radius: 10, y: 5)
        }
    }

    private func detail(_ title: LocalizedStringKey, value: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(Color.themeSurface.opacity(0.88))
                .frame(width: 36, height: 36)
                .background(Color.themeSurface.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.themeSurface.opacity(0.82))

                Text(value)
                    .font(.footnote.bold())
                    .foregroundStyle(Color.themeSurface)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AppointmentSummaryView(doctor: Doctor.samples[0], slot: .sample())
        .padding()
        .background(Theme.roseCanvas)
}
