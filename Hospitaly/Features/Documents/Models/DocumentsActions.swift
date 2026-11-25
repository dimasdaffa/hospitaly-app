//
//  DocumentsActions.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

struct DocumentsActions {
    let load: @MainActor () async throws -> [PatientDocument]
    let loadHistory: @MainActor () async throws -> [PatientDocument]
    let upload: @MainActor (DocumentDraft) async throws -> PatientDocument
    let update: @MainActor (UUID, DocumentDraft) async throws -> PatientDocument
    let delete: @MainActor (UUID) async throws -> Void
    let download: @MainActor (PrivateDocumentDownload) async throws -> Data
}
