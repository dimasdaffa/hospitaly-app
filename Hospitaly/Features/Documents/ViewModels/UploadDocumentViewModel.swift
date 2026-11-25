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
    private struct PendingUpload {
        let upload: DocumentUpload
        let knownIDs: Set<UUID>
    }

    var name = ""
    var cardNumber = ""
    var category: DocumentCategory = .bpjs

    private(set) var file: UploadDocumentFile?
    private(set) var fileError: String?
    private(set) var submissionError: String?
    private(set) var isPicking = false
    private(set) var isSubmitting = false
    private var pending: PendingUpload?

    var needsCheck: Bool { pending != nil }
    var isBusy: Bool { isPicking || isSubmitting }
    var inputDisabled: Bool { isBusy || needsCheck }
    var canSubmit: Bool { !inputDisabled && validatedUpload != nil }

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

    func submit(
        knownIDs: Set<UUID>, using request: @MainActor (DocumentUpload) async throws -> PatientDocument
    ) async -> PatientDocument? {
        guard canSubmit, let upload = validatedUpload, !Task.isCancelled else { return nil }
        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }

        do {
            let saved = try await request(upload)
            guard upload.matches(saved), saved.download != nil else { throw APIError.invalidPayload }
            return saved
        } catch APIError.httpStatus(413) {
            submissionError = "The server rejected the file size. Choose a smaller file."
        } catch APIError.httpStatus(415) {
            submissionError = "The server could not accept this file format."
        } catch APIError.httpStatus(let status) where [400, 401, 403, 404].contains(status) {
            submissionError = APIError.httpStatus(status).localizedDescription
        } catch {
            // shortcut: Document creation has no replay key. Check the saved bytes before offering a retry.
            pending = PendingUpload(upload: upload, knownIDs: knownIDs)
            submissionError = "The upload could not be confirmed. Check Documents before uploading again."
        }
        return nil
    }

    func check(using actions: DocumentsActions) async -> (documents: [PatientDocument], saved: PatientDocument?)? {
        guard let pending, !isBusy, !Task.isCancelled else { return nil }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let rows = try await actions.load()
            let candidates = rows.filter {
                !pending.knownIDs.contains($0.id) && pending.upload.matches($0)
            }

            for candidate in candidates {
                guard let file = candidate.download else { continue }
                let bytes = try await actions.download(file)
                try Task.checkCancellation()
                if bytes == pending.upload.file.data {
                    self.pending = nil
                    submissionError = nil
                    return (rows, candidate)
                }
            }

            try Task.checkCancellation()
            self.pending = nil
            submissionError = "A matching upload could not be found. You can submit it again."
            return (rows, nil)
        } catch where !Task.isCancelled && !(error is CancellationError) {
            submissionError = "Couldn’t check the upload. Try checking Documents again."
        } catch {
            return nil
        }
        return nil
    }

    private var validatedUpload: DocumentUpload? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let number = cardNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let file, !name.isEmpty, metadataError == nil, category != .clinicalAttachment else { return nil }
        return DocumentUpload(name: name, cardNumber: number.isEmpty ? nil : number, category: category, file: file)
    }
}
