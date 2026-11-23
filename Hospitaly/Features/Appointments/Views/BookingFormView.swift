//
//  BookingFormView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct BookingFormView: View {
    let doctor: Doctor
    let slot: AppointmentSlot
    let onConfirm: (String, String) -> Void

    @State private var reason = ""
    @State private var complaints = ""
    @State private var didSubmit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AppointmentSummaryView(doctor: doctor, slot: slot)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Reason for Visit")
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Main Reason *")
                            .font(.subheadline.weight(.semibold))

                        TextField("e.g., General Checkup, Follow-up", text: $reason)
                            .padding(14)
                            .background(Color.themeSurface, in: .rect(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.themeOutline, lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Complaints")
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Text("Optional")
                                .font(.caption)
                                .foregroundStyle(Color.themeMutedText)
                        }

                        TextField("Describe your symptoms, duration, or any specific concerns…", text: $complaints, axis: .vertical)
                            .lineLimit(5...7)
                            .padding(14)
                            .background(Color.themeSurface, in: .rect(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.themeOutline, lineWidth: 1)
                            }
                    }
                }
                .foregroundStyle(Color.themeText)
            }
            .frame(maxWidth: 508)
            .padding(18)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: "Confirm Appointment", icon: "arrow.right", action: confirm)
                .disabled(didSubmit || reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: 508)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.themeSurface, ignoresSafeAreaEdges: .bottom)
        }
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func confirm() {
        let mainReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !didSubmit, !mainReason.isEmpty else { return }

        didSubmit = true
        onConfirm(mainReason, complaints.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

#Preview {
    NavigationStack {
        BookingFormView(doctor: Doctor.samples[0], slot: .sample()) { _, _ in }
    }
}
