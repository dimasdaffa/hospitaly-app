//
//  AppointmentResponse.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct AppointmentResponse: Decodable {
    let id: UUID
    let doctor: DoctorResponse?
    let doctorId: UUID
    let date: String
    let time: String
    let endTime: String?
    let reason: String
    let complaints: String?
    let status: String
    let referenceNumber: String
}
