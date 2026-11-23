//
//  DoctorSearchBar.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorSearchBar: View {
    @Binding var searchText: String
    @Binding var favoritesOnly: Bool
    @Binding var availableOnly: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.themeMutedText)

            TextField(
                "Search doctor or specialty...",
                text: $searchText,
                prompt: Text("Search doctor or specialty...")
                    .foregroundStyle(Color.themeMutedText)
            )
            .font(.subheadline)
            .foregroundStyle(Color.themeText)
            .autocorrectionDisabled()
            .submitLabel(.search)

            Menu {
                Toggle("Favorites only", isOn: $favoritesOnly)
                Toggle("Available only", isOn: $availableOnly)
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.themePrimary)
                    .frame(width: 32, height: 44)
                    .background {
                        if favoritesOnly || availableOnly {
                            Circle()
                                .fill(Color.themePrimary.opacity(0.10))
                                .frame(width: 32, height: 32)
                        }
                    }
            }
        }
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .frame(minHeight: 46)
        .background(Color.themeSurface, in: Capsule())
    }
}

#Preview {
    @Previewable @State var viewModel = DoctorListViewModel(doctors: Doctor.samples)

    DoctorSearchBar(
        searchText: $viewModel.searchText,
        favoritesOnly: $viewModel.favoritesOnly,
        availableOnly: $viewModel.availableOnly
    )
    .padding()
    .background(Color.themeCanvas)
}
