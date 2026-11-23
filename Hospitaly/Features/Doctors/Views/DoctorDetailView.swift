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

                    Text(doctor.bio)
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

                            Text(doctor.practiceLocation)
                                .font(.footnote)
                                .foregroundStyle(Color.themeSecondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.themeSurface, in: .rect(cornerRadius: 16))
                }

                if doctor.isAvailable {
                    DoctorScheduleView(viewModel: viewModel)
                } else {
                    DoctorWeeklyScheduleView()
                }
            }
            .frame(maxWidth: 508)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if doctor.isAvailable {
                DoctorBookingBar(slot: viewModel.selectedSlot, fee: doctor.consultationFee, onContinue: onContinue)
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
