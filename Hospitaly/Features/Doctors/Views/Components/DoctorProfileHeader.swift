//
//  DoctorProfileHeader.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorProfileHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let doctor: Doctor

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 14))

        VStack(alignment: .leading, spacing: 18) {
            layout {
                identity
                    .frame(maxWidth: .infinity, alignment: .leading)

                DoctorAvatarView(doctor: doctor, size: 136, height: 166)
                    .padding(5)
                    .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: 28))
            }

            HStack(spacing: 0) {
                statistic(
                    "Experience", value: "\(doctor.experienceYears) yrs"
                )
                Divider().frame(height: 24)
                statistic(
                    "Patients", value: doctor.patientCount.formatted(.number.notation(.compactName))
                )
                Divider().frame(height: 24)
                statistic(
                    "Rating", value: doctor.rating.formatted(.number.precision(.fractionLength(1)))
                )
            }
            .padding(.vertical, 10)
            .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(doctor.specialty)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeCrimsonInk)

            Text(doctor.name)
                .font(.largeTitle.bold())
                .tracking(-0.8)
                .foregroundStyle(Color.themeText)
                .fixedSize(horizontal: false, vertical: true)

            if let license = doctor.license {
                Text("STR/SIP: \(license)")
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
            }
        }
    }

    private func statistic(_ title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(Color.themeText)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color.themeSecondaryText)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    DoctorProfileHeader(doctor: Doctor.samples[0])
        .padding()
        .background(Theme.roseCanvas)
}
