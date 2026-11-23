//
//  DoctorDetailViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Observation

@Observable
final class DoctorDetailViewModel {
    let doctor: Doctor
    let days: [Date]
    private let firstBookableDate: Date
    private let appointments: [Appointment]

    var selectedDate: Date {
        didSet {
            if !ClinicDate.calendar.isDate(selectedDate, inSameDayAs: oldValue) {
                selectedSlot = nil
            }
        }
    }

    private(set) var selectedSlot: AppointmentSlot?

    init(doctor: Doctor, appointments: [Appointment]) {
        self.doctor = doctor
        self.appointments = appointments
        let calendar = ClinicDate.calendar
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        let firstDate = calendar.date(byAdding: .day, value: doctor.firstBookableDayOffset, to: today) ?? today

        days = (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        firstBookableDate = firstDate
        let lastSlotToday = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today
        if firstDate == today && now >= lastSlotToday {
            selectedDate = calendar.date(byAdding: .day, value: 1, to: today) ?? firstDate
        } else {
            selectedDate = firstDate
        }
    }

    var dateRange: ClosedRange<Date> {
        (days.first ?? selectedDate)...(days.last ?? selectedDate)
    }

    var slots: [AppointmentSlot] {
        let calendar = ClinicDate.calendar
        let day = calendar.startOfDay(for: selectedDate)
        let firstDay = calendar.isDate(day, inSameDayAs: firstBookableDate)
        let now = Date.now
        let starts = [540, 570, 600, 630, 660, 690, 780, 810, 840, 870, 900]

        return starts.compactMap { minutes in
            guard let start = calendar.date(
                bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day
            ) else { return nil }

            let booked = appointments.contains { appointment in
                appointment.doctor.id == doctor.id
                    && appointment.status != .completed
                    && appointment.slot.start == start
            }
            let demoAvailable = start > now && day >= firstBookableDate
                && (!firstDay || minutes / 60 >= doctor.firstBookableHour)
                && minutes != 660

            return AppointmentSlot(
                start: start,
                end: start.addingTimeInterval(1_800),
                isAvailable: doctor.isAvailable && demoAvailable && !booked
            )
        }
    }

    func selectSlot(_ slot: AppointmentSlot) {
        guard slot.isAvailable else { return }
        selectedSlot = slot
    }
}
