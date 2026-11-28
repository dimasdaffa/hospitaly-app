//
//  LogVitalView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct LogVitalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LogVitalViewModel

    let range: ClosedRange<Date>
    let actions: HealthTrackerActions
    let onSaved: (HealthReading, HealthMetric) -> Void
    let onCheckLogs: (HealthMetric) -> Void

    init(
        metric: HealthMetric, latestReading: HealthReading?,
        range: ClosedRange<Date>, actions: HealthTrackerActions,
        onSaved: @escaping (HealthReading, HealthMetric) -> Void, onCheckLogs: @escaping (HealthMetric) -> Void
    ) {
        _viewModel = State(initialValue: LogVitalViewModel(metric: metric, latestReading: latestReading))
        self.range = range
        self.actions = actions
        self.onSaved = onSaved
        self.onCheckLogs = onCheckLogs
    }

    var body: some View {
        @Bindable var model = viewModel

        ScrollView {
            VStack(spacing: 20) {
                header

                VStack(spacing: 22) {
                    VitalMetricTabs(selection: $model.metric, metrics: [.bloodPressure, .heartRate, .weight])

                    if model.usesKeyboard {
                        HStack(alignment: .top, spacing: 12) {
                            field(model.metric == .bloodPressure ? "Systolic" : model.metric.title, text: $model.primary)
                            if model.metric == .bloodPressure {
                                field("Diastolic", text: $model.secondary)
                            }
                        }
                    } else {
                        wheels
                    }

                    Button(model.usesKeyboard ? "Use Wheel" : "Type a Value", action: model.toggleEntryMode)
                        .buttonStyle(.plain)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.themeSecondaryText)
                }
                .disabled(model.isSaving || model.saveUnconfirmed)

                lastReadingCard

                if let message = model.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if model.saveUnconfirmed {
                    PrimaryActionButton(title: "Check Recent Logs", cornerRadius: 27, action: close)
                } else {
                    PrimaryActionButton(
                        title: model.isSaving ? "Saving…" : "Save Entry", icon: "arrow.right",
                        cornerRadius: 27, action: save
                    )
                    .disabled(!model.canSave)
                }
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .hospitalyActionBar()
            .overlay(alignment: .top) { Divider() }
        }
        .interactiveDismissDisabled(model.isSaving || model.saveUnconfirmed)
        .task(id: model.metric) { await model.loadLatest(in: range, using: actions.load) }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Log Vitals")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)
            Text("Enter your latest reading")
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            Button(action: close) {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.themeSecondaryText)
                    .frame(width: 34, height: 34)
                    .background(Color.themeSubtleSurface, in: .circle)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSaving)
        }
    }

    @ViewBuilder
    private var wheels: some View {
        @Bindable var model = viewModel

        switch model.metric {
        case .bloodPressure:
            HStack(spacing: 10) {
                VitalNumberWheel(
                    title: "Systolic", unit: model.metric.unit, values: LogVitalViewModel.pressureValues,
                    selection: $model.systolic
                )
                Text("/")
                    .font(.title2.weight(.light))
                    .foregroundStyle(Color.themeOutline)
                    .padding(.top, 21)
                VitalNumberWheel(
                    title: "Diastolic", unit: model.metric.unit, values: LogVitalViewModel.pressureValues,
                    selection: $model.diastolic
                )
            }
        case .heartRate:
            VitalNumberWheel(
                title: model.metric.title, unit: model.metric.unit, values: LogVitalViewModel.pulseValues,
                selection: $model.pulse, digitSize: 56
            )
            .frame(maxWidth: 300)
        case .weight:
            VitalNumberWheel(
                title: model.metric.title, unit: model.metric.unit, values: LogVitalViewModel.weightTenths,
                selection: $model.weight, decimalPlaces: 1, digitSize: 56
            )
            .frame(maxWidth: 300)
        }
    }

    private var lastReadingCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.themeCrimsonInk)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text("Last Reading")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeText)
                Text(lastReadingDescription)
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)

                if case .failed = viewModel.lastReading {
                    Button("Retry") {
                        Task {
                            guard case .failed = viewModel.lastReading else { return }
                            await viewModel.loadLatest(in: range, using: actions.load)
                        }
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .hospitalyPanel(cornerRadius: 20)
    }

    private var lastReadingDescription: String {
        switch viewModel.lastReading {
        case .loading: "Loading previous reading…"
        case .empty: "No previous reading in this date range."
        case .failed: "Couldn’t load the previous reading."
        case .found(let reading):
            if let value = reading.measurement(for: viewModel.metric) {
                "\(viewModel.metric.format(primary: value.primary, secondary: value.secondary)) • \(reading.dateLabel)"
            } else {
                "No previous reading in this date range."
            }
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeSecondaryText)

            HStack {
                TextField(title, text: text)
                    .keyboardType(viewModel.metric == .weight ? .decimalPad : .numberPad)
                    .font(.title2.bold())

                Text(viewModel.metric.unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.themeMutedText)
            }
            .padding(12)
            .background(Color.themeSurface, in: .rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.themeOutline, lineWidth: 1) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        Task {
            let metric = viewModel.metric
            if let reading = await viewModel.save(using: actions.save) {
                onSaved(reading, metric)
                dismiss()
            }
        }
    }

    private func close() {
        if viewModel.saveUnconfirmed {
            onCheckLogs(viewModel.metric)
        }
        dismiss()
    }
}

#Preview("Blood Pressure") {
    NavigationStack {
        LogVitalView(
            metric: .bloodPressure, latestReading: HealthReading.samples.first,
            range: HealthTrackerViewModel().range, actions: .preview, onSaved: { _, _ in }, onCheckLogs: { _ in }
        )
    }
}

#Preview("Weight") {
    NavigationStack {
        LogVitalView(
            metric: .weight, latestReading: nil, range: HealthTrackerViewModel().range,
            actions: HealthTrackerActions(load: { _, _ in [] }, save: HealthTrackerActions.preview.save),
            onSaved: { _, _ in }, onCheckLogs: { _ in }
        )
    }
}

#Preview("Heart Rate") {
    NavigationStack {
        LogVitalView(
            metric: .heartRate, latestReading: HealthReading.samples.first,
            range: HealthTrackerViewModel().range, actions: .preview, onSaved: { _, _ in }, onCheckLogs: { _ in }
        )
    }
}
