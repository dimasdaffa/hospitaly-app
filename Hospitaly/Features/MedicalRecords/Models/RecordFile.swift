//
//  RecordFile.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct RecordFile: Hashable, Sendable {
    enum Source: Hashable, Sendable {
        case lab(UUID)
        case attachment(UUID)
    }

    let source: Source
    let name: String
    let mediaType: String

    var exportName: String {
        let clean = name.components(separatedBy: .controlCharacters.union(CharacterSet(charactersIn: "/\\:")))
            .joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty || clean == "." || clean == ".." ? "Medical document" : String(clean.prefix(100))
    }
}
