//
//  DoctorListView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct DoctorListView: View {
    @State private var viewModel = DoctorListViewModel()
    @State private var demoAppointments = Appointment.samples
    @State private var availabilityRevision = 0

    @Binding var path: [DoctorRoute]
    let loadDoctors: @MainActor () async throws -> [Doctor]
    var loadDoctorDetails: (@MainActor (String, ClosedRange<Date>) async throws -> DoctorDetailData)? = nil
    var loadAppointments: (@MainActor () async throws -> [Appointment])? = nil
    var bookAppointment: (@MainActor (BookingRequest, Doctor) async throws -> Appointment)? = nil
    var appointmentManagement: AppointmentManagement? = nil

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Text("Our Specialists")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeText)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.themeSurface, ignoresSafeAreaEdges: .top)
                    .overlay(alignment: .trailing) {
                        Button {
                            path.append(.appointments(seed: nil))
                        } label: {
                            Image(systemName: "calendar")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(Color.themePrimary)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 10)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.themeDivider)
                            .frame(height: 1)
                    }

                DoctorSearchBar(
                    searchText: $viewModel.searchText,
                    favoritesOnly: $viewModel.favoritesOnly,
                    availableOnly: $viewModel.availableOnly
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                DoctorSpecialtyFilters(
                    specialties: viewModel.specialties,
                    selection: $viewModel.selectedSpecialty
                )
                .padding(.top, 24)

                ScrollView {
                    directoryContent
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity)
            .background(Color.themeCanvas.ignoresSafeArea())
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: DoctorRoute.self) { route in
                switch route {
                case .detail(let doctor):
                    DoctorDetailView(doctor: doctor, appointments: demoAppointments, loadDetails: loadDoctorDetails) {
                        updatedDoctor, slot in
                        path.append(.booking(updatedDoctor, slot))
                    }
                    .id(availabilityRevision)
                case .booking(let doctor, let slot):
                    bookingForm(doctor: doctor, slot: slot)
                case .confirmation(let appointment):
                    BookingConfirmationView(
                        appointment: appointment,
                        onViewAppointments: { path = [.appointments(seed: appointment)] },
                        onBackToDoctors: { path.removeAll() }
                    )
                case .appointments(let seed, let presentation):
                    MyAppointmentsView(
                        appointments: loadAppointments == nil ? demoAppointments : (seed.map { [$0] } ?? []),
                        loadAppointments: loadAppointments,
                        management: appointmentManagement, presenting: presentation
                    )
                }
            }
        }
        .tint(Color.themePrimary)
        .task(id: viewModel.loadAttempt) { await viewModel.load(using: loadDoctors) }
    }

    @ViewBuilder
    private var directoryContent: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("Loading doctors…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn’t Load Doctors", systemImage: "exclamationmark.circle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry", action: viewModel.retry)
                    .buttonStyle(.borderedProminent)
            }
        case .loaded:
            let doctors = viewModel.filteredDoctors
            if viewModel.doctors.isEmpty {
                ContentUnavailableView {
                    Label("No Doctors Listed", systemImage: "stethoscope")
                } description: {
                    Text("The clinic hasn’t added any doctors yet.")
                } actions: {
                    Button("Refresh", action: viewModel.retry)
                        .buttonStyle(.bordered)
                }
            } else if doctors.isEmpty {
                ContentUnavailableView {
                    Label("No Matching Doctors", systemImage: "magnifyingglass")
                } description: {
                    Text("Try a different search or clear your filters.")
                } actions: {
                    Button("Clear Filters", action: viewModel.resetFilters)
                        .buttonStyle(.bordered)
                }
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(doctors) { doctor in
                        DoctorCardView(
                            doctor: doctor,
                            isFavorite: viewModel.favoriteDoctorIDs.contains(doctor.id),
                            onFavorite: { viewModel.toggleFavorite(doctor.id) },
                            onOpenDoctor: { path.append(.detail(doctor)) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private func bookingForm(doctor: Doctor, slot: AppointmentSlot) -> BookingFormView {
        BookingFormView(
            doctor: doctor,
            slot: slot,
            submitBooking: { booking in try await submit(booking, doctor: doctor, slot: slot) },
            onBooked: { appointment in
                guard path.last == .booking(doctor, slot) else { return }
                path = [.confirmation(appointment)]
            },
            onChooseAnotherTime: {
                guard path.last == .booking(doctor, slot) else { return }
                availabilityRevision += 1
                path.removeLast()
            }
        )
    }

    private func submit(_ booking: BookingRequest, doctor: Doctor, slot: AppointmentSlot) async throws -> Appointment {
        if doctor.usesDemoSchedule {
            let appointment = Appointment(
                doctor: doctor, slot: slot, reason: booking.reason, complaints: booking.complaints ?? ""
            )
            demoAppointments.append(appointment)
            return appointment
        }

        guard let bookAppointment else { throw APIError.invalidConfiguration }
        return try await bookAppointment(booking, doctor)
    }
}

#Preview("Directory") {
    @Previewable @State var path: [DoctorRoute] = []
    DoctorListView(path: $path, loadDoctors: { Doctor.samples })
}

#Preview("Empty Directory") {
    @Previewable @State var path: [DoctorRoute] = []
    DoctorListView(path: $path, loadDoctors: { [] })
}

#Preview("Request Failed") {
    @Previewable @State var path: [DoctorRoute] = []
    DoctorListView(path: $path, loadDoctors: { throw APIError.connectionFailed })
}
