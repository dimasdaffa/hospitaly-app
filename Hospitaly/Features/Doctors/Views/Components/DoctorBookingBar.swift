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
    let fee: Int
    let onContinue: (AppointmentSlot) -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SELECTED SLOT")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.themeMutedText)

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
                    Text("FEE")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.themeMutedText)

                    Text(fee, format: .currency(code: "IDR").precision(.fractionLength(0)).locale(Locale(identifier: "id_ID")))
                        .font(.headline.bold())
                        .foregroundStyle(Color.themeText)
                }
            }

            PrimaryActionButton(title: "Continue to Reason", icon: "arrow.right") {
                if let slot { onContinue(slot) }
            }
            .disabled(slot == nil)
        }
        .frame(maxWidth: 508)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(Color.themeSurface, ignoresSafeAreaEdges: .bottom)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.themeDivider)
                .frame(height: 1)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DoctorBookingBar(slot: .sample(), fee: 150_000) { _ in }
        DoctorBookingBar(slot: nil, fee: 150_000) { _ in }
    }
    .background(Color.themeDetailCanvas)
}
