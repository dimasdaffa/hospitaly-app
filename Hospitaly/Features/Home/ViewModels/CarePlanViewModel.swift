//
//  CarePlanViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class CarePlanViewModel {
    enum Phase: Equatable {
        case loading
        case loaded([CarePlanEntry])
        case failed(String)
    }

    private(set) var phase: Phase
    private(set) var savingID: CarePlanEntry.ID?
    private(set) var saveError: String?
    @ObservationIgnored private var currentRequest: UUID?

    init(phase: Phase = .loading) {
        self.phase = phase
    }

    func load(using request: @MainActor (String) async throws -> [CarePlanEntry]) async {
        guard savingID == nil, !Task.isCancelled else { return }
        let requestID = UUID()
        currentRequest = requestID
        phase = .loading
        saveError = nil

        do {
            let entries = try await request(ClinicDate.dayString(.now))
            try Task.checkCancellation()
            guard requestID == currentRequest else { return }
            phase = .loaded(entries)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, requestID == currentRequest else { return }
            phase = .failed(error.localizedDescription)
        }
    }

    func markTaken(
        _ entry: CarePlanEntry, using request: @MainActor (CarePlanEntry) async throws -> CarePlanEntry
    ) async {
        guard savingID == nil, !Task.isCancelled, case .loaded(var entries) = phase,
              let index = entries.firstIndex(where: { $0.id == entry.id && $0.takenAt == nil }) else { return }
        guard entries[index].date == ClinicDate.dayString(.now) else {
            saveError = "The clinic date has changed. Refresh to see today’s care plan."
            return
        }

        savingID = entry.id
        saveError = nil
        defer { savingID = nil }

        do {
            entries[index] = try await request(entries[index])
            phase = .loaded(entries)
        } catch is CancellationError {
            return
        } catch {
            saveError = error.localizedDescription
        }
    }
}
