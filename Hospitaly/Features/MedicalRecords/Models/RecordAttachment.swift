//
//  RecordAttachment.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct RecordAttachment: Decodable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let mediaType: String
    let size: Int
    let createdAt: Date?
    let downloadPath: String?

    var file: PrivateDocumentDownload? {
        guard downloadPath != nil else { return nil }
        return PrivateDocumentDownload(source: .document(id), name: name, mediaType: mediaType)
    }
}
