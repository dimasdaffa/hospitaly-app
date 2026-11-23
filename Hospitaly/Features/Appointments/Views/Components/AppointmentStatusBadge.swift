//
//  AppointmentStatusBadge.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct AppointmentStatusBadge: View {
    let status: Appointment.Status

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch status {
        case .pending, .cancellationRequested: .themePendingText
        case .approved: .themeAvailableText
        case .rejected, .cancelled: .themePrimary
        case .completed, .unknown: .themeSecondaryText
        }
    }

    private var background: Color {
        switch status {
        case .pending, .cancellationRequested: .themePendingBackground
        case .approved: .themeAvailableBackground
        case .rejected, .cancelled: .themePrimary.opacity(0.08)
        case .completed, .unknown: .themeSubtleSurface
        }
    }
}

#Preview {
    HStack {
        AppointmentStatusBadge(status: .pending)
        AppointmentStatusBadge(status: .approved)
        AppointmentStatusBadge(status: .completed)
    }
    .padding()
}
