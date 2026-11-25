//
//  ProfileViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation
import Observation

@Observable
final class ProfileViewModel {
    let original: UserProfile
    var name: String
    var email: String
    var phone: String
    var dateOfBirth: String
    var gender: String
    var address: String
    var city: String
    var province: String
    var postalCode: String
    var emergencyContact: String
    var emergencyPhone: String

    private(set) var photo: ProfilePhoto?
    private(set) var removesPhoto = false
    private(set) var isPreparingPhoto = false
    private(set) var isSaving = false
    private(set) var photoError: String?
    private(set) var saveError: String?
    private var uploadedPhotoPath: String?

    init(profile: UserProfile) {
        original = profile
        name = profile.name
        email = profile.email
        phone = profile.phone ?? ""
        dateOfBirth = profile.dateOfBirth ?? ""
        gender = profile.gender ?? ""
        address = profile.address ?? ""
        city = profile.city ?? ""
        province = profile.province ?? ""
        postalCode = profile.postalCode ?? ""
        emergencyContact = profile.emergencyContact ?? ""
        emergencyPhone = profile.emergencyPhone ?? ""
    }

    var isBusy: Bool { isPreparingPhoto || isSaving }
    var canSave: Bool {
        !isBusy && validationMessage == nil && (!changes.isEmpty || photo != nil || removesPhoto)
    }

    var validationMessage: String? {
        let request = changes
        if request.name == "" { return "Enter your full name." }
        if let email = request.email, !AccountInput.validEmail(email) {
            return "Enter a valid email address."
        }
        if let birthDate = request.dateOfBirth, !birthDate.isEmpty {
            guard let date = ClinicDate.date(day: birthDate, time: "00:00"),
                  ClinicDate.dayString(date) == birthDate, date <= .now else {
                return "Use YYYY-MM-DD for a birth date in the past or today."
            }
        }
        let fields = [request.name, request.phone, request.gender, request.address, request.city,
                      request.province, request.postalCode, request.emergencyContact, request.emergencyPhone]
        if fields.compactMap({ $0 }).contains(where: { $0.unicodeScalars.count > 255 }) {
            return "Keep each profile field within 255 characters."
        }
        return nil
    }

    func selectPhoto(using load: () async throws -> Data?) async {
        guard !isBusy, !Task.isCancelled else { return }
        isPreparingPhoto = true
        photoError = nil
        defer { isPreparingPhoto = false }

        do {
            guard let data = try await load() else { throw APIError.invalidPayload }
            let prepared = try await ProfilePhoto.prepare(data)
            try Task.checkCancellation()
            photo = prepared
            removesPhoto = false
            uploadedPhotoPath = nil
        } catch where !Task.isCancelled && !(error is CancellationError) {
            photoError = "Couldn’t open the selected photo. Choose another image."
        } catch {
            return
        }
    }

    func restoreCurrentPhoto() {
        photo = nil
        removesPhoto = false
        photoError = nil
        uploadedPhotoPath = nil
    }

    func removePhoto() {
        restoreCurrentPhoto()
        removesPhoto = original.avatarURL != nil
    }

    func save(using actions: ProfileSettingsActions) async -> Bool {
        guard canSave, !Task.isCancelled else { return false }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        do {
            var request = changes
            if let photo {
                if uploadedPhotoPath == nil {
                    uploadedPhotoPath = try await actions.uploadPhoto(photo.jpeg)
                }
                request.avatarURL = uploadedPhotoPath
            } else if removesPhoto {
                request.avatarURL = ""
            }
            try await actions.updateProfile(request)
            return true
        } catch where !Task.isCancelled && !(error is CancellationError) {
            saveError = error.localizedDescription
        } catch {
            return false
        }
        return false
    }

    private var changes: ProfileUpdateRequest {
        ProfileUpdateRequest(
            name: changed(name, from: original.name),
            email: changed(email, from: original.email),
            phone: changed(phone, from: original.phone),
            dateOfBirth: changed(dateOfBirth, from: original.dateOfBirth),
            gender: changed(gender, from: original.gender),
            address: changed(address, from: original.address),
            city: changed(city, from: original.city),
            province: changed(province, from: original.province),
            postalCode: changed(postalCode, from: original.postalCode),
            emergencyContact: changed(emergencyContact, from: original.emergencyContact),
            emergencyPhone: changed(emergencyPhone, from: original.emergencyPhone),
            avatarURL: nil
        )
    }

    private func changed(_ value: String, from original: String?) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = original?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed == previous ? nil : trimmed
    }
}
