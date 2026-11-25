//
//  UploadDocumentViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation
import Observation

@Observable
final class UploadDocumentViewModel {
    private struct PendingSave {
        let draft: DocumentDraft
        let knownIDs: Set<UUID>
    }

    let original: PatientDocument?
    var name: String
    var cardNumber: String
    var category: DocumentCategory

    private(set) var file: UploadDocumentFile?
    private(set) var fileError: String?
    private(set) var submissionError: String?
    private(set) var isPicking = false
    private(set) var isSubmitting = false
    private var pending: PendingSave?
    private var originalIsUnavailable = false

    init(original: PatientDocument? = nil) {
        self.original = original
        name = original?.name ?? ""
        cardNumber = original?.cardNumber ?? ""
        category = original?.category ?? .bpjs
    }

    var needsCheck: Bool { pending != nil }
    var isBusy: Bool { isPicking || isSubmitting }
    var inputDisabled: Bool { isBusy || needsCheck || originalIsUnavailable }
    var canSubmit: Bool { !inputDisabled && fileError == nil && validatedDraft != nil }

    var metadataError: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).utf8.count > 255 {
            return "Document name is too long."
        }
        if cardNumber.trimmingCharacters(in: .whitespacesAndNewlines).utf8.count > 255 {
            return "Card number is too long."
        }
        return nil
    }

    func selectFile(_ selection: Result<URL, any Error>) async {
        guard !inputDisabled, !Task.isCancelled else { return }
        fileError = nil
        isPicking = true
        defer { isPicking = false }

        file = nil
        do {
            let selected = try selection.get()
            let imported = try await UploadDocumentFile.load(from: selected)
            try Task.checkCancellation()
            file = imported
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = selected.deletingPathExtension().lastPathComponent
            }
        } catch let error as UploadDocumentFile.FileError {
            fileError = error.localizedDescription
        } catch where !Task.isCancelled && !(error is CancellationError) {
            fileError = UploadDocumentFile.FileError.unreadable.localizedDescription
        } catch {
            return
        }
    }

    func keepCurrentFile() {
        guard original != nil, !inputDisabled else { return }
        file = nil
        fileError = nil
    }

    func submit(
        knownIDs: Set<UUID>, using actions: DocumentsActions
    ) async -> PatientDocument? {
        guard canSubmit, let draft = validatedDraft, !Task.isCancelled else { return nil }
        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }

        do {
            let saved: PatientDocument
            if let original {
                saved = try await actions.update(original.id, draft)
                guard saved.id == original.id else { throw APIError.invalidPayload }
            } else {
                saved = try await actions.upload(draft)
            }
            guard draft.matches(saved), saved.download != nil else { throw APIError.invalidPayload }
            return saved
        } catch APIError.httpStatus(413) {
            submissionError = "The server rejected the file size. Choose a smaller file."
        } catch APIError.httpStatus(415) {
            submissionError = "The server could not accept this file format."
        } catch APIError.httpStatus(409) {
            submissionError = "This file is linked to a published lab result."
        } catch APIError.httpStatus(404) where original != nil {
            pending = PendingSave(draft: draft, knownIDs: knownIDs)
            submissionError = "This document may have been removed. Check Documents to refresh it."
        } catch APIError.httpStatus(let status) where [400, 401, 403, 404].contains(status) {
            submissionError = APIError.httpStatus(status).localizedDescription
        } catch {
            // shortcut: There is no replay key. Confirm the saved fields and any replacement bytes before retrying.
            pending = PendingSave(draft: draft, knownIDs: knownIDs)
            submissionError = "The save could not be confirmed. Check Documents before trying again."
        }
        return nil
    }

    func check(using actions: DocumentsActions) async -> (documents: [PatientDocument], saved: PatientDocument?)? {
        guard let pending, !isBusy, !Task.isCancelled else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let rows = try await actions.load()
            try Task.checkCancellation()
            let candidates: [PatientDocument]
            if let original {
                candidates = rows.filter { $0.id == original.id && $0.canManage }
                if candidates.isEmpty {
                    originalIsUnavailable = true
                    self.pending = nil
                    submissionError = "This document is no longer available for editing."
                    return (rows, nil)
                }
            } else {
                candidates = rows.filter { !pending.knownIDs.contains($0.id) }
            }

            for candidate in candidates where pending.draft.matches(candidate) {
                guard let download = candidate.download else { continue }
                if let file = pending.draft.file {
                    let bytes = try await actions.download(download)
                    try Task.checkCancellation()
                    guard bytes == file.data else { continue }
                }
                self.pending = nil
                submissionError = nil
                return (rows, candidate)
            }

            try Task.checkCancellation()
            self.pending = nil
            submissionError = "The saved document does not match your changes. You can try again."
            return (rows, nil)
        } catch where !Task.isCancelled && !(error is CancellationError) {
            submissionError = "Couldn’t verify the save. Try checking Documents again."
        } catch {
            return nil
        }
        return nil
    }

    private var validatedDraft: DocumentDraft? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let number = cardNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, metadataError == nil, category != .clinicalAttachment else { return nil }
        let preservedNumber = cardNumber == original?.cardNumber ? original?.cardNumber : (number.isEmpty ? nil : number)
        let draft = DocumentDraft(name: name, cardNumber: preservedNumber, category: category, file: file)
        if let original {
            guard original.canManage, file != nil || !draft.matches(original) else { return nil }
        } else {
            guard file != nil else { return nil }
        }
        return draft
    }
}
