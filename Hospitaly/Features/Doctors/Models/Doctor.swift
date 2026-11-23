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
    let license: String
    let patientCount: Int
    let bio: String
    let practiceLocation: String
    let consultationFee: Int
    var firstBookableDayOffset = 0
    var firstBookableHour = 9

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
            nextAvailable: "Today, 2:00 PM",
            license: "12.3.4.56.7.8.91011",
            patientCount: 1_000,
            bio: "Dr. Strange is a neurosurgeon with experience in complex spinal surgery and neurological disorders. He focuses on helping patients understand their treatment options and plan their recovery.",
            practiceLocation: "Gedung A, Lantai 2, Poli Saraf",
            consultationFee: 150_000,
            firstBookableHour: 14
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
            nextAvailable: nil,
            license: "12.3.4.56.7.8.91012",
            patientCount: 860,
            bio: "Dr. Wilson specializes in oncology and supports patients with individualized treatment plans, follow-up care, and guidance throughout their visits.",
            practiceLocation: "Gedung B, Lantai 2, Poli Onkologi",
            consultationFee: 165_000
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
            nextAvailable: "Tomorrow, 9:00 AM",
            license: "12.3.4.56.7.8.91013",
            patientCount: 720,
            bio: "Dr. Palmer is an emergency medicine specialist with experience in urgent care and acute illness. She helps patients identify next steps and coordinate referrals when needed.",
            practiceLocation: "Gedung A, Lantai 1, Poli Umum",
            consultationFee: 125_000,
            firstBookableDayOffset: 1
        )
    ]
}
