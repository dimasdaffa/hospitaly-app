//
//  DocumentsPreviewData.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

extension PatientDocument {
    fileprivate static let sampleBytes =
        Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMQbnEBAAGJANyw+OyyAAAAAElFTkSuQmCC") ?? Data()

    static let sampleCard: PatientDocument = {
        let id = UUID()
        let now = Date.now
        return PatientDocument(
            id: id, name: "Demo BPJS Card", cardNumber: "000000000001", category: .bpjs,
            mediaType: "image/png", size: sampleBytes.count, createdAt: now, updatedAt: now, deletedAt: nil,
            downloadPath: "/api/documents/\(id)/download"
        )
    }()
}

extension DocumentsActions {
    static let preview = makePreview(hasDocuments: true)
    static let emptyPreview = makePreview(hasDocuments: false)

    private static func makePreview(hasDocuments: Bool) -> DocumentsActions {
        let bytes = PatientDocument.sampleBytes
        let familyCard = sample("Demo Family Card", category: .familyCard, bytes: bytes)
        let clinical = sample("Demo Care Attachment", category: .clinicalAttachment, bytes: bytes)
        let deleted = sample("Old Demo Insurance", category: .insurance, bytes: bytes, deletedAt: .now)
        var rows = hasDocuments ? [.sampleCard, familyCard, clinical, deleted] : []
        var files = Dictionary(uniqueKeysWithValues: rows.filter { $0.deletedAt == nil }.map { ($0.id, bytes) })

        return DocumentsActions(
            load: { rows.filter { $0.deletedAt == nil } },
            loadHistory: { rows },
            upload: { upload in
                guard let file = upload.file else { throw APIError.invalidPayload }
                let id = UUID()
                let now = Date.now
                let document = PatientDocument(
                    id: id, name: upload.name, cardNumber: upload.cardNumber, category: upload.category,
                    mediaType: file.format.mediaType, size: file.data.count,
                    createdAt: now, updatedAt: now, deletedAt: nil, downloadPath: "/api/documents/\(id)/download"
                )
                rows.insert(document, at: 0)
                files[id] = file.data
                return document
            },
            update: { id, draft in
                guard let old = rows.first(where: { $0.id == id && $0.canManage }) else {
                    throw APIError.httpStatus(404)
                }
                let document = PatientDocument(
                    id: id, name: draft.name, cardNumber: draft.cardNumber, category: draft.category,
                    mediaType: draft.file?.format.mediaType ?? old.mediaType, size: draft.file?.data.count ?? old.size,
                    createdAt: old.createdAt, updatedAt: .now, deletedAt: nil, downloadPath: old.downloadPath
                )
                rows.removeAll { $0.id == id }
                rows.insert(document, at: 0)
                if let file = draft.file { files[id] = file.data }
                return document
            },
            delete: { id in
                guard let old = rows.first(where: { $0.id == id && $0.canManage }) else {
                    throw APIError.httpStatus(404)
                }
                let now = Date.now
                let deleted = PatientDocument(
                    id: id, name: old.name, cardNumber: old.cardNumber, category: old.category,
                    mediaType: old.mediaType, size: old.size, createdAt: old.createdAt,
                    updatedAt: now, deletedAt: now, downloadPath: nil
                )
                rows.removeAll { $0.id == id }
                rows.insert(deleted, at: 0)
                files.removeValue(forKey: id)
            },
            download: { file in
                guard case .document(let id) = file.source, let contents = files[id] else {
                    throw APIError.httpStatus(404)
                }
                return contents
            }
        )
    }

    private static func sample(
        _ name: String, category: DocumentCategory, bytes: Data, deletedAt: Date? = nil
    ) -> PatientDocument {
        let id = UUID()
        let createdAt = Date.now.addingTimeInterval(-86_400)
        return PatientDocument(
            id: id, name: name, cardNumber: nil, category: category, mediaType: "image/png",
            size: bytes.count, createdAt: createdAt, updatedAt: deletedAt ?? createdAt, deletedAt: deletedAt,
            downloadPath: deletedAt == nil ? "/api/documents/\(id)/download" : nil
        )
    }
}
