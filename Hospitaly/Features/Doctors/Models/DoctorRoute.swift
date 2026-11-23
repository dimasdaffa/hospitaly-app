//
//  DoctorRoute.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

enum DoctorRoute: Hashable {
    case detail(Doctor)
    case booking(Doctor, AppointmentSlot)
    case confirmation(Appointment)
    case appointments
}
