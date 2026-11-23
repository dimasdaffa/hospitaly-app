//
//  AppointmentCardView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct AppointmentCardView: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                DoctorAvatarView(doctor: appointment.doctor, size: 54, showsAvailability: false)

                VStack(alignment: .leading, spacing: 5) {
                    Text(appointment.doctor.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    Text(appointment.doctor.specialty)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.themePrimary)

                    Label("\(appointment.slot.dateLabel) · \(appointment.slot.timeLabel)", systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AppointmentStatusBadge(status: appointment.status)
            }

            Divider()

            HStack {
                Text(appointment.reason)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeText)

                Spacer(minLength: 10)

                Text(appointment.referenceNumber)
                    .font(.caption)
                    .foregroundStyle(Color.themeMutedText)
            }
        }
        .padding(16)
        .background(Color.themeSurface, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.themeCardBorder, lineWidth: 1)
        }
        .shadow(color: Color.themeCardShadow.opacity(0.5), radius: 2, y: 1)
    }
}

#Preview {
    AppointmentCardView(appointment: .sample)
        .padding()
        .background(Color.themeCanvas)
}
