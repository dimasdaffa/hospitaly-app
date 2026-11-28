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
    let submitBooking: @MainActor (BookingRequest) async throws -> Appointment
    let onBooked: (Appointment) -> Void
    let onChooseAnotherTime: () -> Void

    @State private var viewModel = BookingViewModel()

    var body: some View {
        @Bindable var model = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AppointmentSummaryView(doctor: doctor, slot: slot)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Reason for Visit")
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Main Reason *")
                            .font(.subheadline.weight(.semibold))

                        TextField("e.g., General Checkup, Follow-up", text: $model.reason)
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

                        TextField("Describe your symptoms, duration, or any specific concerns…", text: $model.complaints, axis: .vertical)
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
                .padding(16)
                .hospitalyPanel()
                .disabled(viewModel.hasAttempt || viewModel.slotUnavailable)

                if viewModel.slotUnavailable {
                    Text("This time is no longer available. Choose another slot to continue.")
                        .foregroundStyle(Color.themePrimary)
                        .font(.footnote)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(Color.themePrimary)
                        .font(.footnote)
                } else if viewModel.exceedsLengthLimit {
                    Text("The reason and complaints are limited to 255 bytes each.")
                        .foregroundStyle(Color.themePrimary)
                        .font(.footnote)
                }
            }
            .frame(maxWidth: 508)
            .padding(18)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if viewModel.slotUnavailable {
                    PrimaryActionButton(title: "Choose Another Time", action: onChooseAnotherTime)
                } else {
                    PrimaryActionButton(
                        title: submitTitle, icon: "arrow.right", isLoading: viewModel.isSubmitting, action: confirm
                    )
                    .disabled(!viewModel.canSubmit)
                }
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .hospitalyActionBar()
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isSubmitting)
    }

    private var submitTitle: LocalizedStringKey {
        if viewModel.isSubmitting { return "Submitting…" }
        return viewModel.hasAttempt ? "Retry Submission" : "Confirm Appointment"
    }

    private func confirm() {
        Task {
            if let appointment = await viewModel.submit(doctor: doctor, slot: slot, using: submitBooking) {
                onBooked(appointment)
            }
        }
    }
}

#Preview {
    NavigationStack {
        BookingFormView(
            doctor: Doctor.samples[0], slot: .sample(),
            submitBooking: { _ in .sample },
            onBooked: { _ in },
            onChooseAnotherTime: {}
        )
    }
}
