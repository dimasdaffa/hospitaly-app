//
//  VitalChartView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Charts
import Foundation
import SwiftUI

struct VitalChartView: View {
    private struct Point: Identifiable {
        let id: UUID
        let date: Date
        let measurement: HealthReading.Measurement
    }

    @State private var touchDate: Date?
    @State private var inspectedDate: Date?

    let metric: HealthMetric
    let readings: [HealthReading]
    let days: Int
    let range: ClosedRange<Date>

    var body: some View {
        let values = readings.compactMap { $0.measurement(for: metric) }
        let average = average(values)
        let points = chartPoints

        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                header(average)

                VStack(alignment: .leading, spacing: 12) {
                    if points.isEmpty {
                        Text("No dated readings to plot.")
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        if metric == .bloodPressure {
                            Label("Systolic trend", systemImage: "waveform.path.ecg")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.themeCrimsonInk)
                        }
                        plot(points)
                    }
                }
                .padding(18)
            }
            .clipShape(.rect(cornerRadius: Theme.cardRadius))
            .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))

            HStack(spacing: 10) {
                statistic("Average", value: average)
                statistic(metric == .bloodPressure ? "Highest systolic" : "Highest", value: values.max { $0.primary < $1.primary })
                statistic(metric == .bloodPressure ? "Lowest systolic" : "Lowest", value: values.min { $0.primary < $1.primary })
            }
        }
    }

    private func header(_ average: HealthReading.Measurement?) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Average \(metric.title)")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
                Text("Last \(days) days")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text(numberLabel(average))
                    .font(.largeTitle.bold())
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(metric.unit)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSurface.opacity(0.84))
            }
        }
        .foregroundStyle(Color.themeSurface)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { CrimsonHeaderBackdrop() }
    }

    private var dateDomain: ClosedRange<Date> {
        let end = ClinicDate.calendar.date(byAdding: .day, value: 1, to: range.upperBound) ?? range.upperBound
        return range.lowerBound...end
    }

    private var chartPoints: [Point] {
        let domain = dateDomain
        return readings.compactMap { reading in
            guard let measurement = reading.measurement(for: metric) else { return nil }
            if let date = reading.chartDate, domain.contains(date) {
                return Point(id: reading.id, date: date, measurement: measurement)
            }
            guard let date = ClinicDate.date(day: reading.date, time: "00:00"), domain.contains(date) else { return nil }
            return Point(id: reading.id, date: date, measurement: measurement)
        }
        .sorted { $0.date < $1.date }
    }

    private func plot(_ points: [Point]) -> some View {
        let values = points.map(\.measurement.primary)
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? minimum
        let padding = max((maximum - minimum) * 0.16, metric == .weight ? 0.8 : 4)
        let floor = max(0, minimum - padding)
        let ceiling = min(Double.greatestFiniteMagnitude, maximum + padding * 2)
        let inspected = inspectedPoint(in: points)

        return Chart {
            ForEach(points) { point in
                AreaMark(
                    x: .value("Time", point.date),
                    yStart: .value("Chart base", floor),
                    yEnd: .value(metric.unit, point.measurement.primary)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(colors: [Color.themeCrimsonShade.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom)
                )
                .alignsMarkStylesWithPlotArea()
            }

            ForEach(points) { point in
                LineMark(x: .value("Time", point.date), y: .value(metric.unit, point.measurement.primary))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(Color.themeVitalAccent)
            }

            if let inspected {
                RuleMark(x: .value("Selected time", inspected.date))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.themeCrimsonInk.opacity(0.30))
            }

            ForEach(points) { point in
                if inspected?.id == point.id {
                    dot(point)
                        .annotation(position: .top, spacing: 6, overflowResolution: .init(x: .fit(to: .chart))) {
                            tooltip(point.measurement)
                        }
                } else {
                    dot(point)
                }
            }
        }
        .chartXScale(domain: dateDomain, range: .plotDimension(padding: 5))
        .chartYScale(domain: floor...ceiling)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
                    .foregroundStyle(Color.themeOutline)
            }
        }
        .chartXAxis {
            AxisMarks(values: axisDates) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(axisLabel(date))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
            }
        }
        .chartXSelection(value: $touchDate)
        .onChange(of: touchDate) { _, date in
            if let date { inspectedDate = date }
        }
        .frame(height: 222)
    }

    private var axisDates: [Date] {
        let step = max(1, days / 4)
        return stride(from: 0, to: days, by: step).compactMap { offset in
            ClinicDate.calendar.date(byAdding: .hour, value: offset * 24 + 12, to: range.lowerBound)
        }
    }

    private func axisLabel(_ date: Date) -> String {
        let style: Date.FormatStyle = days == 7 ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated).day()
        return ClinicDate.label(date, as: style)
    }

    private func tooltip(_ value: HealthReading.Measurement) -> some View {
        VStack(spacing: -2) {
            Text(statisticLabel(value))
                .font(.caption2.bold())
                .monospacedDigit()
                .foregroundStyle(Color.themeSurface)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.themeVitalAccent, in: .rect(cornerRadius: 7))

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 7))
                .foregroundStyle(Color.themeVitalAccent)
        }
    }

    private func dot(_ point: Point) -> some ChartContent {
        PointMark(x: .value("Time", point.date), y: .value(metric.unit, point.measurement.primary))
            .symbol {
                Circle()
                    .fill(Color.themeSurface)
                    .strokeBorder(Color.themeVitalAccent, lineWidth: 1.8)
                    .frame(width: 9, height: 9)
            }
    }

    private func inspectedPoint(in points: [Point]) -> Point? {
        guard let date = inspectedDate else { return points.last }
        return points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    private func average(_ values: [HealthReading.Measurement]) -> HealthReading.Measurement? {
        guard !values.isEmpty else { return nil }
        let count = Double(values.count)
        let primary = values.reduce(0) { $0 + $1.primary / count }
        let secondary = values.compactMap(\.secondary)
        let secondaryCount = Double(secondary.count)
        let secondaryAverage = secondary.isEmpty ? nil : secondary.reduce(0) { $0 + $1 / secondaryCount }
        return HealthReading.Measurement(primary: primary, secondary: secondaryAverage)
    }

    private func numberLabel(_ value: HealthReading.Measurement?) -> String {
        guard let value else { return "—" }
        if let secondary = value.secondary {
            return "\(metric.format(value.primary))/\(metric.format(secondary))"
        }
        return metric.format(value.primary)
    }

    private func statisticLabel(_ value: HealthReading.Measurement) -> String {
        metric == .bloodPressure ? numberLabel(value) : metric.format(primary: value.primary)
    }

    private func statistic(_ title: String, value: HealthReading.Measurement?) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.themeSecondaryText)
            Text(value.map(statisticLabel) ?? "—")
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(Color.themeText)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 4)
        .hospitalyPanel(cornerRadius: 18)
    }
}

#Preview {
    VitalChartView(metric: .bloodPressure, readings: HealthReading.samples, days: 7, range: HealthTrackerViewModel().range)
        .padding()
        .background(Theme.roseCanvas)
}
