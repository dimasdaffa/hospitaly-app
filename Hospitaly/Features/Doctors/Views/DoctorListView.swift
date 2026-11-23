//
//  DoctorListView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorListView: View {
    @State private var viewModel = DoctorListViewModel(doctors: Doctor.samples)
    @State private var path: [DoctorRoute] = []
    @State private var appointments = Appointment.samples

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
                            path.append(.appointments)
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
                    if viewModel.filteredDoctors.isEmpty {
                        ContentUnavailableView("No doctors found", systemImage: "magnifyingglass")
                            .foregroundStyle(Color.themeSecondaryText)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredDoctors) { doctor in
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
                    DoctorDetailView(doctor: doctor, appointments: appointments) { slot in
                        path.append(.booking(doctor, slot))
                    }
                case .booking(let doctor, let slot):
                    BookingFormView(doctor: doctor, slot: slot) { reason, complaints in
                        confirmBooking(doctor: doctor, slot: slot, reason: reason, complaints: complaints)
                    }
                case .confirmation(let appointment):
                    BookingConfirmationView(
                        appointment: appointment,
                        onViewAppointments: { path = [.appointments] },
                        onBackToDoctors: { path.removeAll() }
                    )
                case .appointments:
                    MyAppointmentsView(appointments: appointments)
                }
            }
        }
        .tint(Color.themePrimary)
    }

    private func confirmBooking(doctor: Doctor, slot: AppointmentSlot, reason: String, complaints: String) {
        let appointment = Appointment(doctor: doctor, slot: slot, reason: reason, complaints: complaints)
        appointments.append(appointment)
        path = [.confirmation(appointment)]
    }
}

#Preview {
    DoctorListView()
}
