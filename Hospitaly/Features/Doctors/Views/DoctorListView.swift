//
//  DoctorListView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct DoctorListView: View {
    struct SearchRequest: Equatable {
        let id = UUID()
        let query: String
    }

    @State private var viewModel = DoctorListViewModel()
    @State private var demoAppointments = Appointment.samples
    @State private var availabilityRevision = 0

    @Binding var path: [DoctorRoute]
    let loadDoctors: @MainActor () async throws -> [Doctor]
    var loadDoctorDetails: (@MainActor (String, ClosedRange<Date>) async throws -> DoctorDetailData)? = nil
    var setFavorite: (@MainActor (String, Bool) async throws -> Void)? = nil
    var loadAppointments: (@MainActor () async throws -> [Appointment])? = nil
    var bookAppointment: (@MainActor (BookingRequest, Doctor) async throws -> Appointment)? = nil
    var appointmentManagement: AppointmentManagement? = nil
    var searchRequest: SearchRequest? = nil

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("Our Specialists")
                        .font(.largeTitle.bold())
                        .tracking(-0.8)
                        .foregroundStyle(Color.themeText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        path.append(.appointments(seed: nil))
                    } label: {
                        Label("My Appointments", systemImage: "calendar")
                            .labelStyle(.iconOnly)
                            .font(.headline)
                            .foregroundStyle(Color.themeCrimsonInk)
                            .frame(width: 46, height: 46)
                            .glassEffect(.regular.tint(Color.themeGlassRose).interactive(), in: Circle())
                            .environment(\.colorScheme, .light)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.contentInset)
                .padding(.top, 12)

                DoctorSearchBar(
                    searchText: $viewModel.searchText,
                    favoritesOnly: $viewModel.favoritesOnly,
                    availableOnly: $viewModel.availableOnly
                )
                .padding(.horizontal, Theme.contentInset)
                .padding(.top, 16)

                DoctorSpecialtyFilters(
                    specialties: viewModel.specialties,
                    selection: $viewModel.selectedSpecialty
                )
                .padding(.top, 16)

                ScrollView {
                    directoryContent
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
            .background { Theme.roseCanvas.ignoresSafeArea() }
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
        .onChange(of: searchRequest, initial: true) { _, request in
            guard let request else { return }
            viewModel.resetFilters()
            viewModel.searchText = request.query
        }
        .task(id: viewModel.loadAttempt) { await viewModel.load(using: loadDoctors) }
        .alert("Couldn’t Update Favorite", item: $viewModel.favoriteError) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
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
                            isSavingFavorite: viewModel.savingFavoriteIDs.contains(doctor.id),
                            onFavorite: {
                                Task { await viewModel.toggleFavorite(doctor.id, using: setFavorite) }
                            },
                            onOpenDoctor: { path.append(.detail(doctor)) }
                        )
                    }
                }
                .padding(.horizontal, Theme.contentInset)
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
