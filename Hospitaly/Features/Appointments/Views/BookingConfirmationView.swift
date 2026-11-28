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
                AppointmentSummaryView(appointment: appointment)
            }
            .padding(.horizontal, Theme.contentInset)
            .padding(.vertical, 28)
            .frame(maxWidth: Theme.dashboardWidth)
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
            .padding(.horizontal, Theme.contentInset)
            .padding(.vertical, 14)
            .frame(maxWidth: Theme.dashboardWidth)
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
}

#Preview {
    NavigationStack {
        BookingConfirmationView(appointment: .sample, onViewAppointments: {}, onBackToDoctors: {})
    }
}
