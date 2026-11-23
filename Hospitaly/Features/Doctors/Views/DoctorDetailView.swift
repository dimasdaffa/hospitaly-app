//
//  DoctorDetailView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct DoctorDetailView: View {
    @State private var viewModel: DoctorDetailViewModel
    @State private var showsFullBio = false

    let loadDetails: (@MainActor (String, ClosedRange<Date>) async throws -> DoctorDetailData)?
    let onContinue: (Doctor, AppointmentSlot) -> Void

    init(
        doctor: Doctor,
        appointments: [Appointment],
        loadDetails: (@MainActor (String, ClosedRange<Date>) async throws -> DoctorDetailData)? = nil,
        onContinue: @escaping (Doctor, AppointmentSlot) -> Void
    ) {
        _viewModel = State(initialValue: DoctorDetailViewModel(doctor: doctor, appointments: appointments))
        self.loadDetails = loadDetails
        self.onContinue = onContinue
    }

    var body: some View {
        let doctor = viewModel.doctor

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                DoctorProfileHeader(doctor: doctor)

                VStack(alignment: .leading, spacing: 10) {
                    Text("About Doctor")
                        .font(.title3.bold())
                        .foregroundStyle(Color.themeText)

                    if let bio = doctor.bio {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                            .lineSpacing(4)
                            .lineLimit(showsFullBio ? nil : 3)

                        Button(showsFullBio ? "Read less" : "Read more") {
                            showsFullBio.toggle()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themePrimary)
                        .buttonStyle(.plain)
                    } else {
                        Text("No biography has been added yet.")
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Practice Location")
                        .font(.title3.bold())
                        .foregroundStyle(Color.themeText)

                    HStack(spacing: 14) {
                        Image(systemName: "cross.case.fill")
                            .font(.title3)
                            .foregroundStyle(Color.themePrimary)
                            .frame(width: 48, height: 48)
                            .background(Color.themePrimary.opacity(0.08), in: .rect(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(doctor.hospital)
                                .font(.headline)
                                .foregroundStyle(Color.themeText)

                            if !doctor.practiceLocation.isEmpty {
                                Text(doctor.practiceLocation)
                                    .font(.footnote)
                                    .foregroundStyle(Color.themeSecondaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.themeSurface, in: .rect(cornerRadius: 16))
                }

                scheduleContent
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if doctor.canBookDemoSlot || viewModel.hasBookableSlots {
                DoctorBookingBar(
                    slot: viewModel.selectedSlot,
                    fee: doctor.consultationFee,
                    currency: doctor.consultationCurrency,
                    onContinue: { slot in onContinue(doctor, slot) }
                )
            }
        }
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Doctor Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .task(id: viewModel.loadAttempt) {
            if let loadDetails {
                await viewModel.load(using: loadDetails)
            }
        }
    }

    @ViewBuilder
    private var scheduleContent: some View {
        if viewModel.doctor.canBookDemoSlot {
            slotPicker
        } else if viewModel.doctor.usesDemoSchedule {
            DoctorWeeklyScheduleView()
        } else {
            switch viewModel.phase {
            case .loading:
                ProgressView("Loading doctor details and schedule…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            case .failed(let message):
                ContentUnavailableView {
                    Label("Couldn’t Load Doctor Details", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry", action: viewModel.retry)
                        .buttonStyle(.borderedProminent)
                }
            case .loaded:
                if viewModel.hasScheduledSlots {
                    slotPicker
                }
                if !viewModel.hasBookableSlots {
                    DoctorWeeklyScheduleView(weeklyHours: viewModel.weeklyHours)
                }
            }
        }
    }

    private var slotPicker: some View {
        @Bindable var model = viewModel
        return AppointmentSlotPicker(
            days: model.days, dateRange: model.dateRange, selectedDate: $model.selectedDate,
            slots: model.slots, selectedSlot: model.selectedSlot, onSelectSlot: model.selectSlot
        )
    }
}

#Preview("Available") {
    NavigationStack {
        DoctorDetailView(doctor: Doctor.samples[0], appointments: []) { _, _ in }
    }
}

#Preview("Full Today") {
    NavigationStack {
        DoctorDetailView(doctor: Doctor.samples[1], appointments: []) { _, _ in }
    }
}

#Preview("No Practice Schedule") {
    let doctor = {
        var doctor = Doctor.samples[1]
        doctor.usesDemoSchedule = false
        return doctor
    }()

    NavigationStack {
        DoctorDetailView(
            doctor: doctor,
            appointments: [],
            loadDetails: { _, _ in DoctorDetailData(doctor: doctor, slots: [], weeklyHours: []) },
            onContinue: { _, _ in }
        )
    }
}

#Preview("Slot Availability") {
    let doctor = {
        var doctor = Doctor.samples[0]
        doctor.usesDemoSchedule = false
        return doctor
    }()
    let available = AppointmentSlot.sample()
    let occupied = AppointmentSlot(
        start: available.end, end: available.end.addingTimeInterval(1_800), isAvailable: false
    )

    NavigationStack {
        DoctorDetailView(
            doctor: doctor,
            appointments: [],
            loadDetails: { _, _ in DoctorDetailData(doctor: doctor, slots: [available, occupied], weeklyHours: []) },
            onContinue: { _, _ in }
        )
    }
}
