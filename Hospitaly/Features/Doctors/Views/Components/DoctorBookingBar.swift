//
//  DoctorBookingBar.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct DoctorBookingBar: View {
    let slot: AppointmentSlot?
    let fee: Int?
    var currency: String? = "IDR"
    let onContinue: (AppointmentSlot) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.themeCrimsonInk)

                    if let slot {
                        Text("\(slot.dateLabel) · \(slot.timeLabel)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.themeText)
                    } else {
                        Text("Choose a time")
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Fee")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.themeCrimsonInk)

                    if let fee, let currency {
                        Text(fee, format: .currency(code: currency).precision(.fractionLength(0)).locale(Locale(identifier: "id_ID")))
                            .font(.headline.bold())
                            .foregroundStyle(Color.themeText)
                    } else {
                        Text("Not listed")
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
            }

            PrimaryActionButton(title: "Continue to Reason", icon: "arrow.right", cornerRadius: 24) {
                if let slot { onContinue(slot) }
            }
            .disabled(slot == nil)
        }
        .padding(.horizontal, Theme.contentInset)
        .frame(maxWidth: Theme.dashboardWidth)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .hospitalyActionBar()
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.themeDivider)
                .frame(height: 1)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DoctorBookingBar(slot: .sample(), fee: 150_000, onContinue: { _ in })
        DoctorBookingBar(slot: nil, fee: 150_000, onContinue: { _ in })
    }
    .background(Theme.roseCanvas)
}

#Preview("Fee Unavailable") {
    DoctorBookingBar(slot: .sample(), fee: nil, onContinue: { _ in })
        .background(Theme.roseCanvas)
}
