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
            directory
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: DoctorRoute.self, destination: destination)
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

    @ContentBuilder
    private func destination(_ route: DoctorRoute) -> some View {
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

    private var directory: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: -Theme.heroOverlap) {
                    directoryHeader
                        .hospitalyPageHero(topInset: geometry.safeAreaInsets.top)

                    VStack(alignment: .leading, spacing: 16) {
                        DoctorSearchBar(
                            searchText: $viewModel.searchText,
                            favoritesOnly: $viewModel.favoritesOnly,
                            availableOnly: $viewModel.availableOnly
                        )
                        .padding(.horizontal, Theme.contentInset)

                        DoctorSpecialtyFilters(
                            specialties: viewModel.specialties,
                            selection: $viewModel.selectedSpecialty
                        )

                        directoryContent
                            .padding(.horizontal, Theme.contentInset)
                    }
                    .frame(maxWidth: Theme.dashboardWidth)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.container, edges: .top)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
    }

    private var directoryHeader: some View {
        HStack(spacing: 12) {
            Text("Our Specialists")
                .font(.largeTitle.bold())
                .tracking(-0.8)
                .foregroundStyle(Color.themeSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                path.append(.appointments(seed: nil))
            } label: {
                Label("My Appointments", systemImage: "calendar.badge.clock")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .foregroundStyle(Color.themeSurface)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(Color.themeCrimsonDeep.opacity(0.35)).interactive(), in: Circle())
                    .environment(\.colorScheme, .dark)
            }
            .buttonStyle(.plain)
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
                LazyVStack(alignment: .leading, spacing: 14) {
                    Text(doctors.count == 1 ? "1 specialist" : "\(doctors.count) specialists")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.themeSecondaryText)

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
