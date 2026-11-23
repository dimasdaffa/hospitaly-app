//
//  DoctorProfileHeader.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorProfileHeader: View {
    let doctor: Doctor

    var body: some View {
        VStack(spacing: 20) {
            DoctorAvatarView(doctor: doctor, size: 120)

            VStack(spacing: 6) {
                Text(doctor.name)
                    .font(.title2.bold())
                    .foregroundStyle(Color.themeText)

                Text("STR/SIP: \(doctor.license)")
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)

                Text("\(doctor.specialty) Specialist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themePrimary)
            }
            .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                statistic(
                    "Rating", value: doctor.rating.formatted(.number.precision(.fractionLength(1))),
                    icon: "star", color: .themePrimary, background: Color.themePrimary.opacity(0.07)
                )
                statistic(
                    "Patients", value: doctor.patientCount.formatted(.number.notation(.compactName)),
                    icon: "person.2", color: .themeExperienceAccent, background: .themeExperienceBackground
                )
                statistic(
                    "Experience", value: "\(doctor.experienceYears) yrs",
                    icon: "briefcase", color: .themePurpleAccent, background: .themePurpleBackground
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statistic(
        _ title: LocalizedStringKey, value: String, icon: String, color: Color, background: Color
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(background, in: Circle())

            Text(value)
                .font(.headline.bold())
                .foregroundStyle(Color.themeText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.themeMutedText)
        }
        .frame(maxWidth: .infinity, minHeight: 116)
        .background(Color.themeSurface, in: .rect(cornerRadius: 20))
    }
}

#Preview {
    DoctorProfileHeader(doctor: Doctor.samples[0])
        .padding()
        .background(Color.themeDetailCanvas)
}
