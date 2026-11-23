//
//  DoctorDetailView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorDetailView: View {
    @State private var viewModel: DoctorDetailViewModel
    @State private var showsFullBio = false

    let onContinue: (AppointmentSlot) -> Void

    init(doctor: Doctor, appointments: [Appointment], onContinue: @escaping (AppointmentSlot) -> Void) {
        _viewModel = State(initialValue: DoctorDetailViewModel(doctor: doctor, appointments: appointments))
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

                if doctor.canBookDemoSlot {
                    DoctorScheduleView(viewModel: viewModel)
                } else if doctor.usesDemoSchedule {
                    DoctorWeeklyScheduleView()
                } else {
                    ContentUnavailableView(
                        "Online Scheduling", systemImage: "calendar",
                        description: Text("Online scheduling is coming soon.")
                    )
                }
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if doctor.canBookDemoSlot, let fee = doctor.consultationFee {
                DoctorBookingBar(slot: viewModel.selectedSlot, fee: fee, onContinue: onContinue)
            }
        }
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Doctor Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
    }
}

#Preview("Available") {
    NavigationStack {
        DoctorDetailView(doctor: Doctor.samples[0], appointments: []) { _ in }
    }
}

#Preview("Full Today") {
    NavigationStack {
        DoctorDetailView(doctor: Doctor.samples[1], appointments: []) { _ in }
    }
}
