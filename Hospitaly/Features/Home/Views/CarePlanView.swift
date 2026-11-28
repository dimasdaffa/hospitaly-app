//
//  CarePlanView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct CarePlanView: View {
    let viewModel: CarePlanViewModel
    let onRetry: () -> Void
    let onMarkTaken: (CarePlanEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s Care Plan")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)
                .accessibilityAddTraits(.isHeader)

            switch viewModel.phase {
            case .loading:
                LoadingStateView("Loading care plan…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn’t Load Care Plan", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry", action: onRetry)
                        .buttonStyle(.borderedProminent)
                }
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
            case .loaded(let entries):
                if let error = viewModel.refreshError {
                    RefreshFailureView(message: error, isRetrying: viewModel.isLoading, onRetry: onRetry)
                }
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Doses Scheduled Today", systemImage: "pills",
                        description: Text("Medication scheduled for today will appear here.")
                    )
                    .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
                } else {
                    if let error = viewModel.saveError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color.themePrimary)
                    }

                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .top, spacing: 12) {
                            ForEach(entries) { entry in
                                doseCard(entry)
                            }
                        }
                        .padding(.vertical, 7)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    private func doseCard(_ entry: CarePlanEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundStyle(Color.themeCrimsonInk)
                    .frame(width: 42, height: 42)
                    .background(Color.themeGlassRose, in: .rect(cornerRadius: 13))

                Spacer()

                Image(systemName: entry.takenAt == nil ? "circle" : "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(entry.takenAt == nil ? Color.themeOutline : Color.themeAvailableText)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.medication.name)
                    .font(.headline)
                    .foregroundStyle(Color.themeText)
                Text(entry.medication.dose)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
                Text("Scheduled for \(entry.scheduledTime)")
                    .font(.footnote)
                    .foregroundStyle(Color.themeSecondaryText)

                if let instructions = entry.medication.instructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }

            if let takenAt = entry.takenAt {
                Label("Taken at \(ClinicDate.time(takenAt))", systemImage: "checkmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.themeAvailableText)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            } else {
                Button {
                    onMarkTaken(entry)
                } label: {
                    Text(viewModel.savingID == entry.id ? "Saving…" : "Mark as Taken")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeCrimsonInk)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.themeGlassRose, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.savingID != nil || viewModel.isLoading)
            }
        }
        .padding(16)
        .frame(width: 244, alignment: .leading)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }
}

#Preview("Scheduled and Taken") {
    CarePlanView(
        viewModel: CarePlanViewModel(phase: .loaded([.sample, .takenSample])),
        onRetry: {},
        onMarkTaken: { _ in }
    )
    .padding()
    .background(Theme.roseCanvas)
}

#Preview("Empty Care Plan") {
    CarePlanView(viewModel: CarePlanViewModel(phase: .loaded([])), onRetry: {}, onMarkTaken: { _ in })
        .padding()
        .background(Theme.roseCanvas)
}

#Preview("Care Plan Failed") {
    CarePlanView(
        viewModel: CarePlanViewModel(phase: .failed("Could not reach the server.")),
        onRetry: {},
        onMarkTaken: { _ in }
    )
    .padding()
    .background(Theme.roseCanvas)
}
