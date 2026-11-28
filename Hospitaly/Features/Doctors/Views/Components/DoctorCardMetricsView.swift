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
            HStack(spacing: 12) {
                rating
                experience
            }

            VStack(alignment: .leading, spacing: 4) {
                rating
                experience
            }
        }
    }

    private var rating: some View {
        Label {
            HStack(spacing: 4) {
                Text(doctor.rating, format: .number.precision(.fractionLength(1)))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.themeText)

                if let count = doctor.reviewCount {
                    Text("(\(count))")
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
        } icon: {
            Image(systemName: "star.fill")
                .foregroundStyle(Color.themeCrimsonInk)
        }
        .font(.footnote)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var experience: some View {
        Label {
            Text("\(doctor.experienceYears) years")
                .foregroundStyle(Color.themeSecondaryText)
        } icon: {
            Image(systemName: "briefcase")
                .foregroundStyle(Color.themeCrimsonInk)
        }
        .font(.footnote)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    DoctorCardMetricsView(doctor: Doctor.samples[0])
        .padding()
        .background(Color.themeSurface)
}
