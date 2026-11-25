//
//  PatientDocument.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

struct PatientDocument: Decodable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let cardNumber: String?
    let category: DocumentCategory
    let mediaType: String
    let size: Int
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?
    let downloadPath: String?

    var canManage: Bool { deletedAt == nil && category != .clinicalAttachment }

    var download: PrivateDocumentDownload? {
        guard deletedAt == nil, downloadPath != nil else { return nil }
        return PrivateDocumentDownload(source: .document(id), name: name, mediaType: mediaType)
    }
}
