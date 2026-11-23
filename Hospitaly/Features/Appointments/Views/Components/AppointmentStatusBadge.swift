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
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch status {
        case .pending: .themePendingText
        case .approved: .themeAvailableText
        case .completed: .themeSecondaryText
        }
    }

    private var background: Color {
        switch status {
        case .pending: .themePendingBackground
        case .approved: .themeAvailableBackground
        case .completed: .themeSubtleSurface
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
