//
//  AppointmentPresentation.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

enum AppointmentPresentation: Hashable, Identifiable {
    case details(Appointment)
    case reschedule(Appointment)
    case cancel(Appointment)

    var appointment: Appointment {
        switch self {
        case .details(let appointment), .reschedule(let appointment), .cancel(let appointment):
            appointment
        }
    }

    var id: String {
        switch self {
        case .details: "details-\(appointment.id.uuidString)"
        case .reschedule: "reschedule-\(appointment.id.uuidString)"
        case .cancel: "cancel-\(appointment.id.uuidString)"
        }
    }
}
