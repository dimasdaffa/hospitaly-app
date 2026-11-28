//
//  HealthTrackerView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct HealthTrackerView: View {
    private enum Sheet: String, Identifiable {
        case log, history
        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = HealthTrackerViewModel()
    @State private var sheet: Sheet?
    @State private var opensHistoryAfterEntry = false

    let actions: HealthTrackerActions

    var body: some View {
        @Bindable var model = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VitalMetricTabs(selection: $model.metric)

                content
            }
            .padding(.horizontal, Theme.contentInset)
            .padding(.vertical, 16)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
            Button {
                sheet = .log
            } label: {
                Label("Log Vitals", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.themeSurface)
                    .frame(width: 54, height: 54)
                    .background(Theme.crimsonGradient, in: Circle())
                    .shadow(color: Color.themeVitalAccent.opacity(0.24), radius: 6, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.trailing, Theme.contentInset)
            .padding(.vertical, 10)
            .frame(maxWidth: Theme.dashboardWidth, alignment: .trailing)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Health Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Date Range", selection: $model.days) {
                        ForEach([7, 30, 90], id: \.self) { days in
                            Text("Last \(days) days").tag(days)
                        }
                    }
                } label: {
                    Label("Date Range", systemImage: "calendar")
                }
            }
        }
        .sheet(item: $sheet, onDismiss: openPendingHistory) { selection in
            switch selection {
            case .log:
                LogVitalView(
                    metric: model.metric, latestReading: model.readings.first, range: model.range,
                    actions: actions, onSaved: applySaved, onCheckLogs: checkLogs
                )
                .presentationDetents([.fraction(0.80), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(Color.themeGlassCanvas)
            case .history:
                NavigationStack {
                    VitalLogHistoryView(model: viewModel) {
                        await viewModel.load(using: actions.load)
                    }
                }
                .tint(Color.themePrimary)
            }
        }
        .task(id: model.filter) { await model.load(using: actions.load) }
        .refreshable { await model.load(using: actions.load) }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            LoadingStateView(viewModel.readings.isEmpty ? "Loading readings…" : "Refreshing readings…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, viewModel.readings.isEmpty ? 32 : 6)
        case .failed(let message):
            if viewModel.readings.isEmpty {
                ContentUnavailableView {
                    Label("Couldn’t Load Readings", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry", action: reload)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                RefreshFailureView(message: message, onRetry: reload)
            }
        case .loaded:
            if viewModel.readings.isEmpty {
                ContentUnavailableView {
                    Label("No \(viewModel.metric.title) Readings", systemImage: viewModel.metric.symbol)
                } description: {
                    Text("There are no readings in the last \(viewModel.days) days.")
                } actions: {
                    Button("Log a Reading") { sheet = .log }
                        .buttonStyle(.borderedProminent)
                }
            }
        }

        if !viewModel.readings.isEmpty {
            VitalChartView(
                metric: viewModel.metric, readings: viewModel.readings,
                days: viewModel.days, range: viewModel.range
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Recent Logs")
                        .font(.title3.bold())
                        .foregroundStyle(Color.themeText)
                    Spacer()
                    Button("View All") { sheet = .history }
                        .font(.subheadline.weight(.semibold))
                        .tint(Color.themeCrimsonInk)
                }

                ForEach(viewModel.readings.prefix(3)) { reading in
                    VitalLogRow(metric: viewModel.metric, reading: reading)
                }
            }
        }
    }

    private func reload() {
        Task { await viewModel.load(using: actions.load) }
    }

    private func applySaved(_ reading: HealthReading, metric: HealthMetric) {
        let needsReload = viewModel.metric == metric && viewModel.phase != .loaded
        viewModel.metric = metric
        viewModel.applySaved(reading)
        if needsReload { reload() }
    }

    private func checkLogs(_ metric: HealthMetric) {
        opensHistoryAfterEntry = true
        if viewModel.metric == metric {
            reload()
        } else {
            viewModel.metric = metric
        }
    }

    private func openPendingHistory() {
        guard opensHistoryAfterEntry else { return }
        opensHistoryAfterEntry = false
        sheet = .history
    }
}

#Preview("Readings") {
    NavigationStack {
        HealthTrackerView(actions: .preview)
    }
    .tint(Color.themePrimary)
}

#Preview("Empty Tracker") {
    NavigationStack {
        HealthTrackerView(actions: HealthTrackerActions(load: { _, _ in [] }, save: HealthTrackerActions.preview.save))
    }
    .tint(Color.themePrimary)
}

#Preview("Tracker Failed") {
    NavigationStack {
        HealthTrackerView(actions: HealthTrackerActions(
            load: { _, _ in throw APIError.connectionFailed }, save: HealthTrackerActions.preview.save
        ))
    }
    .tint(Color.themePrimary)
}
