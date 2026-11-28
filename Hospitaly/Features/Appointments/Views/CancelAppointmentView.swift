//
//  CancelAppointmentView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct CancelAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CancellationViewModel()
    @State private var submitted: Appointment?

    let appointment: Appointment
    let submit: @MainActor (Appointment, CancellationRequest) async throws -> Appointment
    let onUpdated: (Appointment) -> Void
    let onRefresh: () -> Void

    var body: some View {
        Group {
            if let submitted {
                AppointmentChangeConfirmationView(appointment: submitted, change: .cancellation) { dismiss() }
            } else {
                form
            }
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle(submitted == nil ? "Cancel Appointment" : "Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .disabled(viewModel.isSubmitting)
            }
        }
        .interactiveDismissDisabled(viewModel.isSubmitting)
    }

    private var form: some View {
        @Bindable var model = viewModel

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppointmentSummaryView(appointment: appointment)

                Label(
                    "The hospital reviews your request before cancelling the appointment.",
                    systemImage: "clock"
                )
                .font(.subheadline)
                .foregroundStyle(Color.themePendingText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themePendingBackground, in: .rect(cornerRadius: 16))

                cancellationReason
                    .disabled(model.hasAttempt)
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) { submitBar }
    }

    private var cancellationReason: some View {
        @Bindable var model = viewModel

        return VStack(alignment: .leading, spacing: 14) {
            Text("Reason for Cancellation")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)

            VStack(spacing: 0) {
                ForEach(CancellationRequest.Reason.allCases) { reason in
                    let isSelected = model.reason == reason

                    Button {
                        model.reason = reason
                    } label: {
                        HStack(spacing: 12) {
                            Text(reason.title)
                            Spacer(minLength: 8)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? Color.themeCrimsonInk : Color.themeMutedText)
                        }
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.themeCrimsonInk : Color.themeText)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 48)
                        .background(isSelected ? Color.themeGlassRose : Color.themeSurface)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])

                    if reason != CancellationRequest.Reason.allCases.last { Divider() }
                }
            }
            .clipShape(.rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.themeGlassRose) }

            VStack(alignment: .leading, spacing: 7) {
                Text("Additional Notes")
                    .font(.subheadline.weight(.semibold))
                TextField("Optional", text: $model.note, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 14))
                    .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.themeGlassRose) }
            }
            .foregroundStyle(Color.themeText)
        }
        .padding(16)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .environment(\.colorScheme, .light)
    }

    private var submitBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Color.themeCrimsonInk)
            } else if viewModel.noteIsTooLong {
                Text("The note is limited to 255 bytes.")
                    .font(.footnote)
                    .foregroundStyle(Color.themeCrimsonInk)
            }

            if viewModel.appointmentChanged {
                PrimaryActionButton(title: "Return to Appointments", icon: "arrow.right") { dismiss() }
            } else {
                PrimaryActionButton(title: submitTitle, action: confirm)
                    .disabled(!viewModel.canSubmit)
            }
        }
        .padding(.horizontal, Theme.contentInset)
        .padding(.vertical, 10)
        .frame(maxWidth: Theme.dashboardWidth)
        .frame(maxWidth: .infinity)
        .hospitalyActionBar()
    }

    private var submitTitle: LocalizedStringKey {
        if viewModel.isSubmitting { return "Submitting…" }
        return viewModel.hasAttempt ? "Retry Submission" : "Submit Cancellation"
    }

    private func confirm() {
        Task {
            if let updated = await viewModel.submit(appointment: appointment, using: submit) {
                submitted = updated
                onUpdated(updated)
            } else if viewModel.appointmentChanged {
                onRefresh()
            }
        }
    }
}

#Preview {
    NavigationStack {
        CancelAppointmentView(
            appointment: .sample,
            submit: { _, _ in throw APIError.connectionFailed },
            onUpdated: { _ in }, onRefresh: {}
        )
    }
}
