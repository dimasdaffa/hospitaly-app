//
//  MedicalRecord.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct MedicalRecord: Decodable, Identifiable, Sendable {
    struct Visit: Decodable, Sendable {
        let date: String?
        let time: String?
        let doctor: DoctorResponse?
    }

    struct Medication: Decodable, Identifiable, Sendable {
        let id: UUID
        let name: String
        let dose: String
        let category: String?
        let instructions: String?
        let times: [String]
    }

    let id: UUID
    let appointment: Visit?
    let diagnosis: String
    let symptoms: String
    let treatment: String
    let prescription: String?
    let notes: String?
    let followUpRequired: Bool
    let followUpDate: String?
    let recordType: String?
    let severity: String?
    let symptomTags: [String]?
    let medications: [Medication]?
    let createdAt: Date?

    var visitDate: Date? {
        guard let day = appointment?.date else { return createdAt }
        return ClinicDate.date(day: day, time: appointment?.time ?? "00:00") ?? createdAt
    }
}
