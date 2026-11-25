//
//  LabResult.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct LabResult: Decodable, Identifiable, Sendable {
    struct Measurement: Decodable, Sendable {
        let name: String
        let value: String
        let unit: String?
        let referenceRange: String?
        let status: String?
    }

    struct Panel: Decodable, Sendable {
        let name: String
        let status: String?
        let summary: String?
        let measurements: [Measurement]
    }

    let id: UUID
    let title: String
    let laboratory: String
    let collectedAt: Date
    let alert: String?
    let panels: [Panel]
    let doctorNote: String?
    let authorName: String?
    let authorSpecialty: String?
    let pdfPath: String?

    var pdf: PrivateDocumentDownload? {
        guard pdfPath != nil else { return nil }
        return PrivateDocumentDownload(source: .lab(id), name: title, mediaType: "application/pdf")
    }
}
