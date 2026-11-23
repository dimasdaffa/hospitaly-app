//
//  DoctorDetailView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorDetailView: View {
    let doctor: Doctor

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    DoctorAvatarView(doctor: doctor, size: 112)

                    Text(doctor.name)
                        .font(.title2.bold())
                        .foregroundStyle(Color.themeText)

                    Text(doctor.specialty)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themePrimary)

                    DoctorCardMetricsView(doctor: doctor)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Practice Location")
                            .font(.headline)

                        Label(doctor.hospital, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                    }

                    Rectangle()
                        .fill(Color.themeDivider)
                        .frame(height: 1)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(doctor.isAvailable ? "Next Available" : "Availability")
                            .font(.headline)

                        Text(doctor.nextAvailable ?? "Full Today")
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
                .foregroundStyle(Color.themeText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.themeSurface, in: .rect(cornerRadius: 18))
            }
            .frame(maxWidth: 508)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.themeCanvas.ignoresSafeArea())
        .navigationTitle("Doctor Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        DoctorDetailView(doctor: Doctor.samples[0])
    }
}
