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
    var isSavingFavorite = false
    var isFavoriteDisabled = false
    let onFavorite: () -> Void
    let onOpenDoctor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                DoctorAvatarView(doctor: doctor, size: 72, height: 80, showsAvailability: false)

                VStack(alignment: .leading, spacing: 5) {
                    Text(doctor.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    Text(doctor.specialty)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeCrimsonInk)

                    if !doctor.hospital.isEmpty {
                        Label(doctor.hospital, systemImage: "mappin")
                            .font(.caption)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                favoriteButton
            }

            DoctorCardMetricsView(doctor: doctor)

            availabilityBand
        }
        .padding(14)
        .hospitalyPanel()
    }

    private var favoriteButton: some View {
        Button(action: onFavorite) {
            Group {
                if isSavingFavorite {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label(
                        isFavorite ? "Remove Favorite" : "Add Favorite",
                        systemImage: isFavorite ? "heart.fill" : "heart"
                    )
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isFavorite ? Color.themeCrimsonInk : Color.themeSecondaryText)
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.themeGlassRose.opacity(0.60), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(isSavingFavorite || isFavoriteDisabled)
    }

    private var availabilityBand: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Label(
                    doctor.isAvailable ? "Next available" : "Availability",
                    systemImage: doctor.isAvailable ? "calendar.badge.clock" : "calendar"
                )
                .font(.caption)
                .foregroundStyle(Color.themeCrimsonInk)

                Text(doctor.nextAvailable ?? (doctor.usesDemoSchedule ? "Full Today" : "No upcoming slots"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onOpenDoctor) {
                HStack(spacing: 6) {
                    Text(doctor.isAvailable ? "Book" : "Details")
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(doctor.isAvailable ? Color.themeSurface : Color.themeCrimsonInk)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(doctor.isAvailable ? Color.themeCrimsonInk : Color.themeSurface, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(Color.themeGlassRose.opacity(0.65), in: .rect(cornerRadius: 18))
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(Doctor.samples) { doctor in
            DoctorCardView(doctor: doctor, isFavorite: false, onFavorite: {}, onOpenDoctor: {})
        }
    }
    .padding()
    .background(Theme.roseCanvas)
}
