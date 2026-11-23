//
//  LogVitalViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class LogVitalViewModel {
    enum LastReading {
        case loading, empty, failed
        case found(HealthReading)
    }

    static let pressureValues = 1...999
    static let pulseValues = 1...300
    static let weightTenths = 1...5_000

    var metric: HealthMetric {
        didSet {
            guard metric != oldValue else { return }
            usesKeyboard = false
            errorMessage = nil
        }
    }
    var systolic: Int? = 120
    var diastolic: Int? = 80
    var pulse: Int? = 72
    var weight: Int? = 721
    var primary = ""
    var secondary = ""

    private var previousReadings: [HealthMetric: LastReading] = [:]
    private(set) var usesKeyboard = false
    private(set) var isSaving = false
    private(set) var saveUnconfirmed = false
    private(set) var errorMessage: String?

    init(metric: HealthMetric, latestReading: HealthReading?) {
        self.metric = metric
        if let latestReading {
            previousReadings[metric] = .found(latestReading)
        }
    }

    var lastReading: LastReading { previousReadings[metric] ?? .loading }
    var canSave: Bool { !isSaving && !saveUnconfirmed && request() != nil }

    func loadLatest(
        in range: ClosedRange<Date>,
        using load: @MainActor (HealthMetric, ClosedRange<Date>) async throws -> [HealthReading]
    ) async {
        let selected = metric
        switch lastReading {
        case .found, .empty: return
        case .loading, .failed: previousReadings[selected] = .loading
        }

        do {
            let result = try await load(selected, range)
            try Task.checkCancellation()
            let latest = result.filter { $0.measurement(for: selected) != nil }
                .max { ($0.chartDate ?? .distantPast) < ($1.chartDate ?? .distantPast) }
            previousReadings[selected] = latest.map(LastReading.found) ?? .empty
        } catch where !Task.isCancelled {
            previousReadings[selected] = .failed
        } catch {
            return
        }
    }

    func toggleEntryMode() {
        errorMessage = nil
        if !usesKeyboard {
            primary = wheelInput.primary
            secondary = wheelInput.secondary
            usesKeyboard = true
            return
        }

        let spacing = CharacterSet.whitespacesAndNewlines
        let input = primary.trimmingCharacters(in: spacing)
        let lowerInput = secondary.trimmingCharacters(in: spacing)
        switch metric {
        case .bloodPressure:
            guard let upper = Int(input), Self.pressureValues.contains(upper),
                  let lower = Int(lowerInput), Self.pressureValues.contains(lower) else {
                errorMessage = "Enter both pressures between 1 and 999 to use the wheels."
                return
            }
            systolic = upper
            diastolic = lower
        case .heartRate:
            guard let value = Int(input), Self.pulseValues.contains(value) else {
                errorMessage = "Enter a whole number between 1 and 300 to use the wheel."
                return
            }
            pulse = value
        case .weight:
            guard let value = parseWeight(input), (0.1...500).contains(value),
                  abs(value * 10 - (value * 10).rounded()) < 0.000_001 else {
                errorMessage = "Enter a weight between 0.1 and 500 kg with one decimal place to use the wheel."
                return
            }
            weight = Int((value * 10).rounded())
        }
        usesKeyboard = false
    }

    private var wheelInput: (primary: String, secondary: String) {
        switch metric {
        case .bloodPressure: (systolic.map(String.init) ?? "", diastolic.map(String.init) ?? "")
        case .heartRate: (pulse.map(String.init) ?? "", "")
        case .weight: (weight.map { String(Double($0) / 10) } ?? "", "")
        }
    }

    private func request() -> HealthReadingRequest? {
        let values = usesKeyboard ? (primary, secondary) : wheelInput
        let input = values.0.trimmingCharacters(in: .whitespacesAndNewlines)
        switch metric {
        case .bloodPressure:
            let lowerInput = values.1.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let systolic = Int(input), let diastolic = Int(lowerInput),
                  Self.pressureValues.contains(systolic), Self.pressureValues.contains(diastolic) else { return nil }
            return HealthReadingRequest(bloodPressure: "\(systolic)/\(diastolic)")
        case .heartRate:
            guard let heartRate = Int32(input), heartRate > 0 else { return nil }
            return HealthReadingRequest(heartRate: Int(heartRate))
        case .weight:
            guard let weight = parseWeight(input) else { return nil }
            return HealthReadingRequest(weight: weight)
        }
    }

    private func parseWeight(_ input: String) -> Double? {
        guard let weight = Double(input.replacingOccurrences(of: ",", with: ".")),
              weight.isFinite, weight > 0 else { return nil }
        return weight
    }

    func save(using submit: @MainActor (HealthReadingRequest) async throws -> HealthReading) async -> HealthReading? {
        guard !isSaving, !saveUnconfirmed, !Task.isCancelled, let request = request() else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let reading = try await submit(request)
            guard reading.date == request.date, reading.measurement(for: metric) != nil else {
                throw APIError.invalidPayload
            }
            return reading
        } catch APIError.httpStatus(let status) where status == 400 || status == 401 || status == 403 {
            errorMessage = APIError.httpStatus(status).localizedDescription
        } catch {
            // shortcut: The API has no replay key. Check the log before another submission.
            saveUnconfirmed = true
            errorMessage = "Couldn’t confirm the save. Check Recent Logs before entering this reading again."
        }
        return nil
    }
}
