//
//  PrivateExportDocument.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI
import UniformTypeIdentifiers

nonisolated final class PrivateExportDocument: WritableDocument {
    static var writableContentTypes: [UTType] {
        [.pdf, .jpeg, .png] + [UTType(filenameExtension: "docx")].compactMap { $0 }
    }

    private let bytes: Data

    init(bytes: Data) {
        self.bytes = bytes
    }

    func writer(configuration: WriteConfiguration) -> FileWrapperDocumentWriter<Data> {
        FileWrapperDocumentWriter(configuration) { data, _ in
            FileWrapper(regularFileWithContents: data)
        }
    }

    @MainActor
    func snapshot(contentType: UTType) async throws -> Data {
        bytes
    }
}
