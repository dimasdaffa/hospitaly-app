//
//  DoctorDetailView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct DoctorDetailView: View {
    private enum Section: String, CaseIterable {
        case appointment = "Appointment"
        case schedule = "Schedule"
        case about = "About"
    }

    @State private var viewModel: DoctorDetailViewModel
    @State private var section: Section = .appointment

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
        ScrollView {
            VStack(spacing: 0) {
                DoctorProfileHeader(doctor: viewModel.doctor)
                    .padding(.horizontal, Theme.contentInset)
                    .padding(.top, 12)
                    .padding(.bottom, 22)

                detailPanel
            }
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if section == .appointment && canBook {
                DoctorBookingBar(
                    slot: viewModel.selectedSlot,
                    fee: viewModel.doctor.consultationFee,
                    currency: viewModel.doctor.consultationCurrency,
                    onContinue: { slot in onContinue(viewModel.doctor, slot) }
                )
            }
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Doctor Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .task(id: viewModel.loadAttempt) {
            if let loadDetails {
                await viewModel.load(using: loadDetails)
            }
        }
    }

    private var canBook: Bool {
        viewModel.doctor.canBookDemoSlot || viewModel.hasBookableSlots
    }

    private var detailPanel: some View {
        VStack(spacing: 0) {
            sectionTabs
                .padding(.horizontal, Theme.contentInset)
                .padding(.top, 14)

            VStack(alignment: .leading, spacing: 20) {
                switch section {
                case .appointment, .schedule:
                    schedulingContent
                case .about:
                    aboutContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.contentInset)
        }
        .background(
            Color.themeSurface.opacity(0.86),
            in: UnevenRoundedRectangle(topLeadingRadius: Theme.cardRadius, topTrailingRadius: Theme.cardRadius)
        )
    }

    private var sectionTabs: some View {
        Picker("Doctor Information", selection: $section) {
            ForEach(Section.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private var aboutContent: some View {
        let doctor = viewModel.doctor

        return VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("About Doctor")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeText)

                Text(doctor.bio ?? "No biography has been added yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Practice Location")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeText)

                HStack(spacing: 14) {
                    Image(systemName: "cross.case.fill")
                        .font(.title3)
                        .foregroundStyle(Color.themeCrimsonInk)
                        .frame(width: 44, height: 44)
                        .background(Color.themeGlassRose, in: .rect(cornerRadius: 14))

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
                .padding(14)
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    @ViewBuilder
    private var schedulingContent: some View {
        if viewModel.doctor.usesDemoSchedule {
            schedules(weeklyHours: nil)
        } else {
            switch viewModel.phase {
            case .loading:
                LoadingStateView("Loading doctor details and schedule…")
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
                schedules(weeklyHours: viewModel.weeklyHours)
            }
        }
    }

    @ViewBuilder
    private func schedules(weeklyHours: [DoctorDetailData.WeeklyHours]?) -> some View {
        if section == .appointment && (viewModel.doctor.canBookDemoSlot || viewModel.hasScheduledSlots) {
            slotPicker
        }
        if section == .schedule || !canBook {
            DoctorWeeklyScheduleView(weeklyHours: weeklyHours, hasBookableSlots: canBook)
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

#Preview("No Practice Schedule or Portrait") {
    let doctor = {
        var doctor = Doctor.samples[1]
        doctor.usesDemoSchedule = false
        doctor.portraitName = nil
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
