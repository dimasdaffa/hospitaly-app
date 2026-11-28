//
//  PrivateDocumentDownload.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct PrivateDocumentDownload: Hashable, Sendable {
    enum Source: Hashable, Sendable {
        case lab(UUID)
        case document(UUID)

        var path: String {
            switch self {
            case .lab(let id): "api/lab-results/\(id)/pdf"
            case .document(let id): "api/documents/\(id)/download"
            }
        }
    }

    let source: Source
    let name: String
    let mediaType: String

    var exportName: String {
        let clean = name.components(separatedBy: .controlCharacters.union(CharacterSet(charactersIn: "/\\:")))
            .joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty || clean == "." || clean == ".." ? "Document" : String(clean.prefix(100))
    }
}
