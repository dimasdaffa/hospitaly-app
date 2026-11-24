//
//  MedicalRecordsViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation
import Observation

@Observable
final class MedicalRecordsViewModel {
    enum Phase {
        case loading, loaded, failed(String)
    }

    struct Month: Identifiable {
        let id: Date?
        var entries: [MedicalRecordEntry]

        var title: String {
            id.map { ClinicDate.label($0, as: .dateTime.month(.wide).year()) } ?? "Unknown date"
        }
    }

    private(set) var phase = Phase.loading
    private(set) var entries: [MedicalRecordEntry] = []
    var filter: MedicalRecordEntry.Kind?
    var query = ""

    var latestVisit: MedicalRecordEntry? {
        guard filter == nil, trimmedQuery.isEmpty else { return nil }
        let today = ClinicDate.calendar.startOfDay(for: .now)
        let end = ClinicDate.calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return entries.first { entry in
            guard entry.kind == .diagnosis, let date = entry.date else { return false }
            return date < end
        }
    }

    var months: [Month] {
        let featuredID = latestVisit?.id
        let search = trimmedQuery
        let filtered = entries.filter { entry in
            guard entry.id != featuredID, filter == nil || entry.kind == filter else { return false }
            return search.isEmpty || [entry.title, entry.provider, entry.subtitle, entry.summary]
                .compactMap { $0 }.contains { $0.localizedStandardContains(search) }
        }

        let calendar = ClinicDate.calendar
        var months: [Month] = []
        for entry in filtered {
            let month = entry.date.flatMap { calendar.dateInterval(of: .month, for: $0)?.start }
            if let last = months.indices.last, months[last].id == month {
                months[last].entries.append(entry)
            } else {
                months.append(Month(id: month, entries: [entry]))
            }
        }
        return months
    }

    func load(using request: @MainActor () async throws -> [MedicalRecordEntry]) async {
        guard !Task.isCancelled else { return }
        phase = .loading
        do {
            let result = try await request()
            try Task.checkCancellation()
            entries = result.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            phase = .loaded
        } catch where !Task.isCancelled && !(error is CancellationError) {
            phase = .failed(error.localizedDescription)
        } catch {
            return
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
