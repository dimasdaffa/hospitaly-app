//
//  DocumentsActions.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

struct DocumentsActions {
    let load: @MainActor () async throws -> [PatientDocument]
    let upload: @MainActor (DocumentUpload) async throws -> PatientDocument
    let download: @MainActor (PrivateDocumentDownload) async throws -> Data
}
