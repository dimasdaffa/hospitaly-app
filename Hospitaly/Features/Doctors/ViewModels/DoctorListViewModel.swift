//
//  DoctorListViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class DoctorListViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    var searchText = ""
    var selectedSpecialty: String?
    var favoritesOnly = false
    var availableOnly = false

    private(set) var doctors: [Doctor] = []
    private(set) var phase: Phase = .loading
    private(set) var loadAttempt = 0
    private(set) var favoriteDoctorIDs: Set<Doctor.ID> = []
    private(set) var savingFavoriteIDs: Set<Doctor.ID> = []
    var favoriteError: String?
    @ObservationIgnored private var currentRequest: UUID?

    init(doctors: [Doctor]? = nil) {
        if let doctors {
            self.doctors = doctors
            favoriteDoctorIDs = Set(doctors.filter(\.isFavorite).map(\.id))
            phase = .loaded
        }
    }

    var specialties: [String] {
        Set(doctors.map(\.specialty)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func load(using request: @MainActor () async throws -> [Doctor]) async {
        guard savingFavoriteIDs.isEmpty, !Task.isCancelled else { return }
        let previous = phase
        let id = UUID()
        currentRequest = id
        phase = .loading

        do {
            let result = try await request()
            try Task.checkCancellation()
            guard currentRequest == id else { return }
            doctors = result
            favoriteDoctorIDs = Set(result.filter(\.isFavorite).map(\.id))
            phase = .loaded
        } catch is CancellationError {
            if currentRequest == id { phase = previous }
        } catch {
            guard currentRequest == id else { return }
            phase = Task.isCancelled ? previous : .failed(error.localizedDescription)
        }
    }

    func retry() {
        guard phase != .loading, savingFavoriteIDs.isEmpty else { return }
        loadAttempt += 1
    }

    func resetFilters() {
        searchText = ""
        selectedSpecialty = nil
        favoritesOnly = false
        availableOnly = false
    }

    var filteredDoctors: [Doctor] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return doctors.filter { doctor in
            let matchesSearch = query.isEmpty
                || doctor.name.localizedStandardContains(query)
                || doctor.specialty.localizedStandardContains(query)
            let matchesSpecialty = selectedSpecialty == nil || doctor.specialty == selectedSpecialty
            let matchesFavorites = !favoritesOnly || favoriteDoctorIDs.contains(doctor.id)
            let matchesAvailability = !availableOnly || doctor.isAvailable

            return matchesSearch && matchesSpecialty && matchesFavorites && matchesAvailability
        }
    }

    func toggleFavorite(
        _ doctorID: Doctor.ID, using request: (@MainActor (String, Bool) async throws -> Void)?
    ) async {
        guard phase != .loading, !Task.isCancelled, savingFavoriteIDs.insert(doctorID).inserted else { return }
        let shouldFavorite = !favoriteDoctorIDs.contains(doctorID)
        defer { savingFavoriteIDs.remove(doctorID) }

        do {
            if let request { try await request(doctorID, shouldFavorite) }
            if shouldFavorite {
                favoriteDoctorIDs.insert(doctorID)
            } else {
                favoriteDoctorIDs.remove(doctorID)
            }
        } catch where !Task.isCancelled && !(error is CancellationError) {
            favoriteError = error.localizedDescription
        } catch {
            return
        }
    }
}
