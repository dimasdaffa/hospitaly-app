//
//  UploadDocumentFile.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Dispatch
import Foundation
import UniformTypeIdentifiers

nonisolated struct UploadDocumentFile: Sendable {
    enum Format: Sendable {
        case pdf, png, jpeg

        var contentType: UTType {
            switch self {
            case .pdf: .pdf
            case .png: .png
            case .jpeg: .jpeg
            }
        }

        var mediaType: String {
            switch self {
            case .pdf: "application/pdf"
            case .png: "image/png"
            case .jpeg: "image/jpeg"
            }
        }

        var fileExtension: String {
            switch self {
            case .pdf: "pdf"
            case .png: "png"
            case .jpeg: "jpg"
            }
        }
    }

    enum FileError: LocalizedError {
        case unreadable, tooLarge, unsupported

        var errorDescription: String? {
            switch self {
            case .unreadable: "Couldn’t open this file. Choose it again from Files."
            case .tooLarge: "Choose a file that is 5 MiB or smaller."
            case .unsupported: "Choose a PDF, JPEG, or PNG file."
            }
        }
    }

    static let maximumBytes = 5 * 1_024 * 1_024
    static let allowedTypes: [UTType] = [Format.pdf.contentType, Format.jpeg.contentType, Format.png.contentType]

    let name: String
    let data: Data
    let format: Format

    static func load(from url: URL) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(with: Result { try readCoordinated(url) })
            }
        }
    }

    private static func readCoordinated(_ url: URL) throws -> Self {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }

        var coordinationError: NSError?
        var result: Result<Self, any Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
            result = Result { try read(readableURL, name: url.lastPathComponent) }
        }

        guard coordinationError == nil, let result else { throw FileError.unreadable }
        return try result.get()
    }

    private static func read(_ url: URL, name: String) throws -> Self {
        guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
              let handle = try? FileHandle(forReadingFrom: url) else { throw FileError.unreadable }
        defer { try? handle.close() }

        let limit = maximumBytes + 1
        var data = Data()
        do {
            while data.count < limit {
                let length = min(limit - data.count, 1_024 * 1_024)
                guard let chunk = try handle.read(upToCount: length), !chunk.isEmpty else { break }
                data.append(chunk)
            }
        } catch {
            throw FileError.unreadable
        }

        guard data.count <= maximumBytes else { throw FileError.tooLarge }
        let format: Format
        if data.starts(with: "%PDF-".utf8) {
            format = .pdf
        } else if data.starts(with: [0xFF, 0xD8, 0xFF]) {
            format = .jpeg
        } else if data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            format = .png
        } else {
            throw FileError.unsupported
        }
        return Self(name: name, data: data, format: format)
    }
}
