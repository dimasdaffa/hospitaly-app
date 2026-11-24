//
//  MedicalRecordEntry.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

enum MedicalRecordEntry: Identifiable, Sendable {
    enum Route: Hashable, Sendable {
        case record(UUID)
        case lab(UUID)
    }

    enum Kind: String, CaseIterable, Identifiable {
        case diagnosis = "Diagnosis"
        case lab = "Lab Results"
        case vaccination = "Vaccination"

        var id: Self { self }

        var symbol: String {
            switch self {
            case .diagnosis: "cross.case"
            case .lab: "testtube.2"
            case .vaccination: "syringe"
            }
        }
    }

    case record(MedicalRecord)
    case lab(LabResult)

    var id: Route {
        switch self {
        case .record(let record): .record(record.id)
        case .lab(let result): .lab(result.id)
        }
    }

    var kind: Kind {
        switch self {
        case .record(let record): record.recordType == "vaccination" ? .vaccination : .diagnosis
        case .lab: .lab
        }
    }

    var date: Date? {
        switch self {
        case .record(let record): record.visitDate
        case .lab(let result): result.collectedAt
        }
    }

    var title: String {
        switch self {
        case .record(let record): record.diagnosis
        case .lab(let result): result.title
        }
    }

    var provider: String? {
        switch self {
        case .record(let record): record.appointment?.doctor?.name
        case .lab(let result): result.laboratory
        }
    }

    var subtitle: String? {
        switch self {
        case .record(let record): record.appointment?.doctor?.specialty
        case .lab: nil
        }
    }

    var summary: String? {
        switch self {
        case .record(let record): record.symptoms
        case .lab(let result): result.alert ?? result.panels.lazy.compactMap(\.summary).first
        }
    }
}
