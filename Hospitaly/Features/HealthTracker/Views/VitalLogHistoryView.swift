//
//  VitalLogHistoryView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 28/11/26.
//

import SwiftUI

struct VitalLogHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    let model: HealthTrackerViewModel
    let onRefresh: @MainActor () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                header
                status
                history
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Vital Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .refreshable { await onRefresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.metric.title)
                .font(.title2.bold())
                .foregroundStyle(Color.themeSurface)

            Label("Last \(model.days) days", systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(Color.themeSurface.opacity(0.88))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            CrimsonHeaderBackdrop()
                .clipShape(.rect(cornerRadius: Theme.cardRadius))
        }
    }

    @ViewBuilder
    private var status: some View {
        switch model.phase {
        case .loading:
            LoadingStateView(model.readings.isEmpty ? "Loading logs…" : "Refreshing logs…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, model.readings.isEmpty ? 32 : 6)
        case .failed(let message):
            if model.readings.isEmpty {
                ContentUnavailableView {
                    Label("Couldn’t Load Logs", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry", action: retry)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                RefreshFailureView(message: message, onRetry: retry)
            }
        case .loaded:
            if model.readings.isEmpty {
                ContentUnavailableView(
                    "No Logs in This Period", systemImage: model.metric.symbol,
                    description: Text("Saved readings will appear here for the selected date range.")
                )
            }
        }
    }

    private var history: some View {
        let readingsByDay = Dictionary(grouping: model.readings, by: \.date)

        return ForEach(readingsByDay.keys.sorted(by: >), id: \.self) { day in
            Section {
                ForEach(readingsByDay[day, default: []]) { reading in
                    VitalLogRow(metric: model.metric, reading: reading, showsDate: false)
                }
            } header: {
                Text(dayLabel(day))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeCrimsonInk)
                    .padding(.top, 8)
            }
        }
    }

    private func dayLabel(_ day: String) -> String {
        guard let date = ClinicDate.date(day: day, time: "00:00") else { return day }
        return ClinicDate.label(date, as: .dateTime.weekday(.wide).day().month(.abbreviated).year())
    }

    private func retry() {
        Task { await onRefresh() }
    }
}

#Preview("Log History") {
    @Previewable @State var model = HealthTrackerViewModel()

    NavigationStack {
        VitalLogHistoryView(model: model) { await model.load(using: HealthTrackerActions.preview.load) }
    }
    .task { await model.load(using: HealthTrackerActions.preview.load) }
    .tint(Color.themePrimary)
}

#Preview("Empty Log History") {
    @Previewable @State var model = HealthTrackerViewModel()

    NavigationStack {
        VitalLogHistoryView(model: model) { await model.load(using: { _, _ in [] }) }
    }
    .task { await model.load(using: { _, _ in [] }) }
    .tint(Color.themePrimary)
}

#Preview("Log History Failed") {
    @Previewable @State var model = HealthTrackerViewModel()

    NavigationStack {
        VitalLogHistoryView(model: model) {
            await model.load(using: { _, _ in throw APIError.connectionFailed })
        }
    }
    .task { await model.load(using: { _, _ in throw APIError.connectionFailed }) }
    .tint(Color.themePrimary)
}
