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
                        .foregroundStyle(Color.themeText)

                    Text(doctor.specialty)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themePrimary)

                    Label(doctor.hospital, systemImage: "mappin")
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }

            Divider()

            HStack(spacing: 16) {
                detail("DATE", value: slot.dateLabel, icon: "calendar")
                detail("TIME", value: slot.timeLabel, icon: "clock")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.themeSurface, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.themeCardBorder, lineWidth: 1)
        }
    }

    private func detail(_ title: LocalizedStringKey, value: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(Color.themePrimary)
                .frame(width: 36, height: 36)
                .background(Color.themePrimary.opacity(0.08), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.themeMutedText)

                Text(value)
                    .font(.footnote.bold())
                    .foregroundStyle(Color.themeText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AppointmentSummaryView(doctor: Doctor.samples[0], slot: .sample())
        .padding()
        .background(Color.themeDetailCanvas)
}
