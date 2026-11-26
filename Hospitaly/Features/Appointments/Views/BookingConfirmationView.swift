//
//  BookingConfirmationView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct BookingConfirmationView: View {
    let appointment: Appointment
    let onViewAppointments: () -> Void
    let onBackToDoctors: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                confirmationHeader
                confirmationCard
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                PrimaryActionButton(
                    title: "View My Appointments", icon: "arrow.right", action: onViewAppointments
                )

                Button(action: onBackToDoctors) {
                    Text("Back to Doctors")
                        .font(.headline)
                        .foregroundStyle(Color.themeSecondaryText)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.themeSurface, in: .rect(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.themeOutline, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .hospitalyActionBar()
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Confirmation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var confirmationHeader: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(Color.themeAvailableDot)
                .frame(width: 96, height: 96)
                .background(Color.themeAvailableBackground.opacity(0.60), in: Circle())
                .padding(.bottom, 4)

            Text(appointment.status == .pending ? "Appointment Requested!" : "Appointment Details")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.themeText)

            if appointment.status == .pending {
                Text("Your request is pending approval.")
                    .font(.body)
                    .foregroundStyle(Color.themeSecondaryText)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var confirmationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("STATUS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.themeMutedText)

                Spacer()

                AppointmentStatusBadge(status: appointment.status)
            }

            HStack(spacing: 14) {
                DoctorAvatarView(doctor: appointment.doctor, size: 60, showsAvailability: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.doctor.name)
                        .font(.headline)

                    if !appointment.doctor.specialty.isEmpty {
                        Text(appointment.doctor.specialty)
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
            }

            Divider()

            row(
                "DATE & TIME", value: appointment.slot.dateLabel, icon: "calendar",
                subtitle: "\(appointment.slot.timeLabel) – \(ClinicDate.time(appointment.slot.end))"
            )
            row(
                "LOCATION", value: appointment.doctor.hospital, icon: "mappin",
                subtitle: appointment.doctor.practiceLocation.isEmpty ? nil : appointment.doctor.practiceLocation
            )
            row("REFERENCE ID", value: appointment.referenceNumber, icon: "doc.text")
        }
        .foregroundStyle(Color.themeText)
        .padding(20)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func row(_ title: LocalizedStringKey, value: String, icon: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondaryText)
                .frame(width: 38, height: 38)
                .background(Color.themeGlassRose.opacity(0.75), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.themeMutedText)

                Text(value)
                    .font(.subheadline.weight(.semibold))

                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BookingConfirmationView(appointment: .sample, onViewAppointments: {}, onBackToDoctors: {})
    }
}
