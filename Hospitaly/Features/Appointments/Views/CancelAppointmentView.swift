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
                CancellationSubmittedView(appointment: submitted) { dismiss() }
            } else {
                form
            }
        }
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Cancel Appointment")
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
                AppointmentSummaryView(doctor: appointment.doctor, slot: appointment.slot)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason for Cancellation")
                        .font(.title3.bold())
                        .foregroundStyle(Color.themeText)
                    Text("Tell us why you’re cancelling so we can improve our service.")
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                }

                VStack(spacing: 0) {
                    ForEach(CancellationRequest.Reason.allCases) { reason in
                        Button {
                            model.reason = reason
                        } label: {
                            HStack {
                                Text(reason.title)
                                    .foregroundStyle(Color.themeText)
                                Spacer()
                                Image(systemName: model.reason == reason ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(model.reason == reason ? Color.themePrimary : Color.themeMutedText)
                            }
                            .padding(16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if reason != .other {
                            Divider()
                        }
                    }
                }
                .background(Color.themeSurface, in: .rect(cornerRadius: 16))
                .disabled(model.hasAttempt)

                TextField("Please specify (optional)", text: $model.note, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(16)
                    .background(Color.themeSurface, in: .rect(cornerRadius: 16))
                    .disabled(model.hasAttempt)

                Label(
                    "The hospital will review your request. Finding another available slot may take time.",
                    systemImage: "exclamationmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(Color.themePrimary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themePrimary.opacity(0.08), in: .rect(cornerRadius: 14))

                if let error = model.errorMessage {
                    Text(error)
                        .foregroundStyle(Color.themePrimary)
                        .font(.footnote)
                } else if model.noteIsTooLong {
                    Text("The note is limited to 255 bytes.")
                        .foregroundStyle(Color.themePrimary)
                        .font(.footnote)
                }
            }
            .frame(maxWidth: 508)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !model.appointmentChanged {
                PrimaryActionButton(title: submitTitle, action: confirm)
                    .disabled(!model.canSubmit)
                    .frame(maxWidth: 508)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.themeSurface, ignoresSafeAreaEdges: .bottom)
            }
        }
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
