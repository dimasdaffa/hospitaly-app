//
//  DoctorListView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorListView: View {
    @State private var viewModel = DoctorListViewModel(doctors: Doctor.samples)
    @State private var selectedDoctor: Doctor?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Our Specialists")
                    .font(.title3.bold())
                    .foregroundStyle(Color.themeText)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color.themeSurface, ignoresSafeAreaEdges: .top)
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
                                    onOpenDoctor: { selectedDoctor = doctor }
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
            .navigationDestination(item: $selectedDoctor) { doctor in
                DoctorDetailView(doctor: doctor)
            }
        }
        .tint(Color.themePrimary)
    }
}

#Preview {
    DoctorListView()
}
