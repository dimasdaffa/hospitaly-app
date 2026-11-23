//
//  CancellationRequest.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

struct CancellationRequest: Encodable, Sendable {
    enum Reason: String, CaseIterable, Identifiable {
        case changeOfPlans = "change_of_plans"
        case foundAnotherDoctor = "found_another_doctor"
        case personalEmergency = "personal_emergency"
        case feelingBetter = "feeling_better"
        case other

        var id: Self { self }

        var title: String {
            switch self {
            case .changeOfPlans: "Change of plans"
            case .foundAnotherDoctor: "Found another doctor"
            case .personalEmergency: "Personal emergency"
            case .feelingBetter: "Feeling better now"
            case .other: "Other"
            }
        }
    }

    let reason: String
    let note: String?
}
