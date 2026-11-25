//
//  DocumentsPreviewData.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

extension DocumentsActions {
    static let preview = makePreview(hasDocuments: true)
    static let emptyPreview = makePreview(hasDocuments: false)

    private static func makePreview(hasDocuments: Bool) -> DocumentsActions {
        let bytes = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMQbnEBAAGJANyw+OyyAAAAAElFTkSuQmCC") ?? Data()
        let card = sample("Demo BPJS Card", category: .bpjs, number: "000000000001", bytes: bytes)
        let familyCard = sample("Demo Family Card", category: .familyCard, number: nil, bytes: bytes)
        var rows = hasDocuments ? [card, familyCard] : []
        var files = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, bytes) })

        return DocumentsActions(
            load: { rows },
            upload: { upload in
                let id = UUID()
                let document = PatientDocument(
                    id: id, name: upload.name, cardNumber: upload.cardNumber, category: upload.category,
                    mediaType: upload.file.format.mediaType, size: upload.file.data.count,
                    createdAt: .now, downloadPath: "/api/documents/\(id)/download"
                )
                rows.insert(document, at: 0)
                files[id] = upload.file.data
                return document
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
        _ name: String, category: DocumentCategory, number: String?, bytes: Data
    ) -> PatientDocument {
        let id = UUID()
        return PatientDocument(
            id: id, name: name, cardNumber: number, category: category, mediaType: "image/png",
            size: bytes.count, createdAt: .now, downloadPath: "/api/documents/\(id)/download"
        )
    }
}
