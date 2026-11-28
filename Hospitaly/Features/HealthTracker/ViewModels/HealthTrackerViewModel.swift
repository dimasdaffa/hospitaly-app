//
//  HealthTrackerViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class HealthTrackerViewModel {
    struct Filter: Equatable {
        let metric: HealthMetric
        let days: Int
    }

    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var metric: HealthMetric = .bloodPressure {
        didSet {
            if oldValue != metric { reset() }
        }
    }
    var days = 7 {
        didSet {
            if oldValue != days { reset() }
        }
    }

    private(set) var phase: Phase = .loading
    private(set) var readings: [HealthReading] = []
    @ObservationIgnored private var currentRequest: UUID?

    var filter: Filter { Filter(metric: metric, days: days) }

    var range: ClosedRange<Date> {
        let calendar = ClinicDate.calendar
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(byAdding: .day, value: 1 - days, to: today) ?? today
        return start...today
    }

    func load(using request: @MainActor (HealthMetric, ClosedRange<Date>) async throws -> [HealthReading]) async {
        guard !Task.isCancelled else { return }
        let previous = phase
        let requestedFilter = filter
        let requestID = UUID()
        currentRequest = requestID
        phase = .loading

        do {
            let result = try await request(requestedFilter.metric, range)
            try Task.checkCancellation()
            guard requestID == currentRequest, requestedFilter == filter else { return }
            readings = newestFirst(result.filter { $0.measurement(for: requestedFilter.metric) != nil })
            phase = .loaded
        } catch is CancellationError {
            if requestID == currentRequest, requestedFilter == filter { phase = previous }
        } catch {
            guard requestID == currentRequest, requestedFilter == filter else { return }
            phase = Task.isCancelled ? previous : .failed(error.localizedDescription)
        }
    }

    func applySaved(_ reading: HealthReading) {
        guard reading.measurement(for: metric) != nil else { return }
        let from = ClinicDate.dayString(range.lowerBound)
        let to = ClinicDate.dayString(range.upperBound)
        guard (from...to).contains(reading.date) else { return }
        currentRequest = nil
        readings = newestFirst(readings.filter { $0.id != reading.id } + [reading])
        phase = .loaded
    }

    private func reset() {
        currentRequest = nil
        readings = []
        phase = .loading
    }

    private func newestFirst(_ values: [HealthReading]) -> [HealthReading] {
        values.sorted { ($0.chartDate ?? .distantPast) > ($1.chartDate ?? .distantPast) }
    }
}
