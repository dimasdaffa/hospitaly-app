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
    var searchText = ""
    var selectedSpecialty: String?
    var favoritesOnly = false
    var availableOnly = false

    private let doctors: [Doctor]
    private(set) var favoriteDoctorIDs: Set<Doctor.ID> = []

    let specialties = ["Cardiology", "Pediatrics", "Neurosurgery", "Oncology", "Emergency Medicine"]

    init(doctors: [Doctor]) {
        self.doctors = doctors
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
        if favoriteDoctorIDs.remove(doctorID) == nil {
            favoriteDoctorIDs.insert(doctorID)
        }
    }
}
