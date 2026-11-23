//
//  Doctor.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

struct Doctor: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let specialty: String
    let hospital: String
    let portraitName: String
    let rating: Double
    let reviewCount: Int
    let experienceYears: Int
    let nextAvailable: String?

    var isAvailable: Bool {
        nextAvailable != nil
    }
}

extension Doctor {
    static let samples: [Doctor] = [
        Doctor(
            id: "stephen-strange",
            name: "Dr. Stephen Strange",
            specialty: "Neurosurgery",
            hospital: "RS Permata Sehat",
            portraitName: "DoctorStephen",
            rating: 4.9,
            reviewCount: 120,
            experienceYears: 15,
            nextAvailable: "Today, 2:00 PM"
        ),
        Doctor(
            id: "james-wilson",
            name: "Dr. James Wilson",
            specialty: "Oncology",
            hospital: "RS Permata Sehat",
            portraitName: "DoctorJames",
            rating: 4.7,
            reviewCount: 42,
            experienceYears: 12,
            nextAvailable: nil
        ),
        Doctor(
            id: "christine-palmer",
            name: "Dr. Christine Palmer",
            specialty: "Emergency Medicine",
            hospital: "RS Permata Sehat",
            portraitName: "DoctorChristine",
            rating: 4.8,
            reviewCount: 95,
            experienceYears: 8,
            nextAvailable: "Tomorrow, 9:00 AM"
        )
    ]
}
