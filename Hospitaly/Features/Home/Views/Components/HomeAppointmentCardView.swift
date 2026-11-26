//
//  HomeAppointmentCardView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct HomeAppointmentCardView: View {
    let appointment: Appointment
    let onDetails: () -> Void
    let onReschedule: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            provider
                .padding(.horizontal, 14)
                .padding(.top, 13)

            VStack(alignment: .leading, spacing: 9) {
                schedule
                actions
            }
            .padding(12)
            .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 17))
            .padding([.horizontal, .bottom], 9)
        }
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius), tone: .crimson)
    }

    private var provider: some View {
        HStack(spacing: 10) {
            DoctorAvatarView(doctor: appointment.doctor, size: 46, showsAvailability: false)

            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.doctor.name)
                    .font(.headline)
                    .foregroundStyle(Color.themeSurface)

                if !appointment.doctor.specialty.isEmpty {
                    Text(appointment.doctor.specialty)
                        .font(.caption)
                        .foregroundStyle(Color.themeSurface.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var schedule: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                visitDate
                visitTime
                Spacer(minLength: 0)
                AppointmentStatusBadge(status: appointment.status)
            }

            VStack(alignment: .leading, spacing: 6) {
                visitDate
                visitTime
                AppointmentStatusBadge(status: appointment.status)
            }
        }
    }

    private var visitDate: some View {
        scheduleFact(
            ClinicDate.label(appointment.slot.start, as: .dateTime.weekday(.abbreviated).month(.abbreviated).day()),
            symbol: "calendar"
        )
    }

    private var visitTime: some View {
        scheduleFact(appointment.slot.timeLabel, symbol: "clock")
    }

    private func scheduleFact(_ title: String, symbol: String) -> some View {
        Label {
            Text(title)
                .foregroundStyle(Color.themeText)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(Color.themeCrimsonInk)
        }
        .font(.footnote.weight(.semibold))
        .fixedSize(horizontal: true, vertical: false)
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { actionButtons }
            VStack(spacing: 8) { actionButtons }
        }
    }

    @ContentBuilder
    private var actionButtons: some View {
        if let onReschedule {
            Button(action: onReschedule) {
                Text("Reschedule")
                    .font(.footnote.weight(.semibold))
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(Color.themeCrimsonInk)
                    .background(Color.themeSurface, in: .capsule)
                    .overlay { Capsule().strokeBorder(Color.themeGlassRose, lineWidth: 1) }
            }
            .buttonStyle(.plain)
        }

        Button(action: onDetails) {
            HStack(spacing: 7) {
                Text("Details")
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
            }
            .font(.footnote.weight(.bold))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(Color.themeSurface)
            .background(Color.themePrimary, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeAppointmentCardView(appointment: .sample, onDetails: {}, onReschedule: {})
        .padding()
        .background(Theme.crimsonGradient)
}
