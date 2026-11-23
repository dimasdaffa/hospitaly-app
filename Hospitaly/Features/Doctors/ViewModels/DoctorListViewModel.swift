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
        guard phase == .loading, !Task.isCancelled else { return }

        do {
            let result = try await request()
            try Task.checkCancellation()
            doctors = result
            favoriteDoctorIDs = Set(result.filter(\.isFavorite).map(\.id))
            phase = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failed(error.localizedDescription)
        }
    }

    func retry() {
        guard phase != .loading else { return }
        phase = .loading
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

    func toggleFavorite(_ doctorID: Doctor.ID) {
        // shortcut: Keep changes in memory until favorite write endpoints are connected.
        if favoriteDoctorIDs.remove(doctorID) == nil {
            favoriteDoctorIDs.insert(doctorID)
        }
    }
}
