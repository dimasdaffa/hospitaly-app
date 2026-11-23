//
//  DoctorCardMetricsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorCardMetricsView: View {
    let doctor: Doctor

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                ratingBadge
                experienceBadge
            }

            VStack(alignment: .leading, spacing: 4) {
                ratingBadge
                experienceBadge
            }
        }
    }

    private var ratingBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.themeRatingAccent)

            Text(doctor.rating, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.themeText)

            if let count = doctor.reviewCount {
                Text("(\(count))")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.themeMutedText)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Color.themeRatingBackground, in: .rect(cornerRadius: 6))
        .fixedSize(horizontal: true, vertical: false)
    }

    private var experienceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "briefcase")
                .foregroundStyle(Color.themeExperienceAccent)

            Text("\(doctor.experienceYears) Years")
                .foregroundStyle(Color.themeSecondaryText)
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Color.themeExperienceBackground, in: .rect(cornerRadius: 6))
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    DoctorCardMetricsView(doctor: Doctor.samples[0])
        .padding()
        .background(Color.themeSurface)
}
