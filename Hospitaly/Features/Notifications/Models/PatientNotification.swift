//
//  PatientNotification.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct PatientNotification: Decodable, Identifiable, Equatable {
    let id: UUID
    let appointmentId: UUID
    let type: String
    let createdAt: Date?
    var readAt: Date?

    var isUnread: Bool { readAt == nil }

    static let sample = PatientNotification(
        id: UUID(), appointmentId: UUID(), type: "approved", createdAt: .now, readAt: nil
    )
}
