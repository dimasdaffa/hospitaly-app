//
//  DoctorSpecialtyFilters.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorSpecialtyFilters: View {
    let specialties: [String]
    @Binding var selection: String?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                chip("All", specialty: nil)

                ForEach(specialties, id: \.self) { specialty in
                    chip(specialty, specialty: specialty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .scrollIndicators(.hidden)
    }

    private func chip(_ title: String, specialty: String?) -> some View {
        let isSelected = selection == specialty

        return Button {
            selection = specialty
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.themeSurface : Color.themeSecondaryText)
                .padding(.horizontal, 20)
                .frame(height: 36)
                .background(isSelected ? Color.themePrimary : Color.themeSurface, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(Color.themeOutline, lineWidth: isSelected ? 0 : 1)
                }
                .shadow(color: isSelected ? Color.themePrimary.opacity(0.20) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var viewModel = DoctorListViewModel(doctors: Doctor.samples)

    DoctorSpecialtyFilters(
        specialties: viewModel.specialties,
        selection: $viewModel.selectedSpecialty
    )
    .padding(.vertical)
    .background(Color.themeCanvas)
}
