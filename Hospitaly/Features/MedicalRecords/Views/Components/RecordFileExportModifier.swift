//
//  RecordFileExportModifier.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct RecordFileExportModifier: ViewModifier {
    @Binding var file: RecordFile?
    let download: @MainActor (RecordFile) async throws -> Data

    @State private var isExporting = false
    @State private var document: RecordExportDocument?
    @State private var exportName: String?
    @State private var exportType: UTType?
    @State private var errorMessage = ""
    @State private var showsError = false

    func body(content: Content) -> some View {
        content
            .task(id: file) { await prepareExport() }
            .fileExporter(
                isPresented: $isExporting, document: document, contentType: exportType,
                defaultFilename: exportName,
                onCompletion: { result in
                    document = nil
                    if case .failure(let error) = result { showError(error.localizedDescription) }
                },
                onCancellation: { document = nil }
            )
            .alert("File Unavailable", isPresented: $showsError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
    }

    private func prepareExport() async {
        guard let file else { return }
        guard let type = RecordExportDocument.writableContentTypes.first(where: { $0.preferredMIMEType == file.mediaType }) else {
            self.file = nil
            showError("This file format is unavailable.")
            return
        }

        do {
            let data = try await download(file)
            try Task.checkCancellation()
            document = RecordExportDocument(bytes: data)

            let filename = file.exportName
            let suffix = type.preferredFilenameExtension
            exportName = (filename as NSString).pathExtension.lowercased() == suffix
                ? (filename as NSString).deletingPathExtension : filename
            exportType = type
            isExporting = true
            self.file = nil
        } catch where !Task.isCancelled && !(error is CancellationError) {
            self.file = nil
            showError(error.localizedDescription)
        } catch {
            return
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showsError = true
    }
}

#Preview("File Download Error") {
    @Previewable @State var file: RecordFile?

    Button("Download PDF") {
        file = RecordFile(source: .lab(UUID()), name: "Demo Lab Report", mediaType: "application/pdf")
    }
    .modifier(RecordFileExportModifier(file: $file, download: { _ in throw APIError.connectionFailed }))
}
