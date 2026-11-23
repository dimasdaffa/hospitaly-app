//
//  DoctorCardView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorCardView: View {
    let doctor: Doctor
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onOpenDoctor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                DoctorAvatarView(doctor: doctor)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(doctor.name)
                            .font(.headline.bold())
                            .foregroundStyle(Color.themeText)

                        Text(doctor.specialty)
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)

                        Label(doctor.hospital, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(Color.themeMutedText)
                    }
                    .padding(.trailing, 40)

                    DoctorCardMetricsView(doctor: doctor)
                }
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 104, alignment: .topLeading)
            .overlay(alignment: .topTrailing) {
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isFavorite ? Color.themePrimary : Color.themeMutedText)
                        .frame(width: 40, height: 42)
                        .background(Color.themeSubtleSurface, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            Rectangle()
                .fill(Color.themeDivider)
                .frame(height: 1)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(doctor.isAvailable ? "NEXT AVAILABLE" : "AVAILABILITY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Color.themeSecondaryText)

                    Text(doctor.nextAvailable ?? (doctor.usesDemoSchedule ? "Full Today" : "No upcoming slots"))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.themeText)
                }

                Spacer(minLength: 0)

                Button(action: onOpenDoctor) {
                    Text(doctor.canBookDemoSlot ? "Book" : "Details")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(doctor.isAvailable ? Color.themeSurface : Color.themeSecondaryText)
                        .frame(minWidth: doctor.isAvailable ? 83 : 95, minHeight: 40)
                        .background(doctor.isAvailable ? Color.themePrimary : Color.themeSubtleSurface, in: Capsule())
                        .shadow(color: doctor.isAvailable ? Color.themePrimary.opacity(0.25) : .clear, radius: 4, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.themeSurface, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.themeCardBorder, lineWidth: 1)
        }
        .shadow(color: Color.themeCardShadow, radius: 2, y: 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Doctor.samples) { doctor in
            DoctorCardView(doctor: doctor, isFavorite: false, onFavorite: {}, onOpenDoctor: {})
        }
    }
    .padding()
    .background(Color.themeCanvas)
}
