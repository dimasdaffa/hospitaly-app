//
//  PersonalInfoView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import PhotosUI
import SwiftUI

struct PersonalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ProfileViewModel
    @State private var selection: PhotosPickerItem?

    let avatarURL: URL?
    let actions: ProfileSettingsActions

    init(profile: UserProfile, avatarURL: URL?, actions: ProfileSettingsActions) {
        _model = State(initialValue: ProfileViewModel(profile: profile))
        self.avatarURL = avatarURL
        self.actions = actions
    }

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                photoEditor
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Personal Details") {
                TextField("Full Name", text: $model.name)
                    .textContentType(.name)
                TextField("Email", text: $model.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Phone", text: $model.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                TextField("Date of Birth (YYYY-MM-DD)", text: $model.dateOfBirth)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Gender", text: $model.gender)
            }

            Section("Address") {
                TextField("Street Address", text: $model.address, axis: .vertical)
                    .textContentType(.fullStreetAddress)
                TextField("City", text: $model.city)
                    .textContentType(.addressCity)
                TextField("Province", text: $model.province)
                    .textContentType(.addressState)
                TextField("Postal Code", text: $model.postalCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numbersAndPunctuation)
            }

            Section("Emergency Contact") {
                TextField("Contact Name", text: $model.emergencyContact)
                    .textContentType(.name)
                TextField("Contact Phone", text: $model.emergencyPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            if let message = model.validationMessage ?? model.saveError {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themePrimary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .environment(\.colorScheme, .light)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .disabled(model.isBusy)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: model.isSaving ? "Saving…" : "Save Changes") {
                Task {
                    if await model.save(using: actions) { dismiss() }
                }
            }
            .disabled(!model.canSave)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .hospitalyActionBar()
        }
        .navigationBarBackButtonHidden(model.isSaving)
        .task(id: selection) {
            guard let selection else { return }
            await model.selectPhoto { try await selection.loadTransferable(type: Data.self) }
        }
    }

    private var photoEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ProfileAvatar(url: model.removesPhoto ? nil : avatarURL, photo: model.photo?.thumbnail, size: 66)

                VStack(alignment: .leading, spacing: 4) {
                    PhotosPicker(selection: $selection, matching: .images) {
                        Label("Choose Profile Photo", systemImage: "photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.themeSurface)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.borderless)

                    if model.isPreparingPhoto {
                        ProgressView("Opening photo…")
                            .font(.footnote)
                            .tint(.themeSurface)
                    }

                    if model.photo != nil || model.removesPhoto {
                        Button("Use Current Photo") {
                            selection = nil
                            model.restoreCurrentPhoto()
                        }
                        .font(.footnote)
                        .buttonStyle(.borderless)
                    } else if model.original.avatarURL != nil {
                        Button("Remove from Profile", role: .destructive) {
                            selection = nil
                            model.removePhoto()
                        }
                        .font(.footnote)
                        .buttonStyle(.borderless)
                    }
                }
                .tint(.themeSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Anyone with the photo link can view it.")
                .font(.caption)
                .foregroundStyle(Color.themeSurface.opacity(0.88))

            if let message = model.photoError {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.footnote)
            }
        }
        .foregroundStyle(Color.themeSurface)
        .padding(16)
        .background {
            CrimsonHeaderBackdrop().clipShape(.rect(cornerRadius: Theme.cardRadius))
        }
    }
}

#Preview {
    NavigationStack {
        PersonalInfoView(profile: .settingsPreview, avatarURL: nil, actions: .preview)
    }
    .tint(Color.themePrimary)
}
