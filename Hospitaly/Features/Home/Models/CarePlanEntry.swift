//
//  CarePlanEntry.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct CarePlanEntry: Decodable, Equatable, Identifiable {
    struct Medication: Decodable, Equatable {
        let id: UUID
        let name: String
        let dose: String
        let instructions: String?
    }

    let recordId: UUID
    let medication: Medication
    let date: String
    let time: String
    var takenAt: Date?

    var id: String {
        "\(recordId.uuidString)/\(medication.id.uuidString)/\(date)/\(time)"
    }

    var scheduledTime: String {
        ClinicDate.date(day: date, time: time).map { ClinicDate.time($0) } ?? time
    }

    static let sample = CarePlanEntry(
        recordId: UUID(),
        medication: Medication(id: UUID(), name: "Demo Medication", dose: "1 tablet", instructions: nil),
        date: ClinicDate.dayString(.now), time: "14:00", takenAt: nil
    )

    static let takenSample = CarePlanEntry(
        recordId: sample.recordId, medication: sample.medication,
        date: sample.date, time: "08:00", takenAt: ClinicDate.date(day: sample.date, time: "08:10")
    )
}
