//
//  DocumentService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

struct DocumentService {
    private struct Metadata: Encodable {
        let name: String
        let category: String
        let cardNumber: String?
    }

    let client: APIClient

    func list(token: String) async throws -> [PatientDocument] {
        try await client.get("api/documents", token: token)
    }

    func history(token: String) async throws -> [PatientDocument] {
        try await client.get("api/documents/history", token: token)
    }

    func upload(_ draft: DocumentDraft, token: String) async throws -> PatientDocument {
        guard let file = draft.file else { throw APIError.invalidPayload }
        return try await sendFile(draft, file: file, path: "api/documents", method: "POST", token: token)
    }

    func update(_ id: UUID, draft: DocumentDraft, token: String) async throws -> PatientDocument {
        let path = "api/documents/\(id)"
        if let file = draft.file {
            return try await sendFile(draft, file: file, path: path, method: "PUT", token: token)
        }
        let body = Metadata(name: draft.name, category: draft.category.rawValue, cardNumber: draft.cardNumber)
        return try await client.put(path, body: body, token: token)
    }

    func delete(_ id: UUID, token: String) async throws {
        try await client.delete("api/documents/\(id)", token: token)
    }

    func download(_ file: PrivateDocumentDownload, token: String) async throws -> Data {
        try await client.getFile(file, token: token)
    }

    private func sendFile(
        _ draft: DocumentDraft, file: UploadDocumentFile, path: String, method: String, token: String
    ) async throws -> PatientDocument {
        let boundary = "Hospitaly-\(UUID().uuidString)"
        var body = Data()
        body.reserveCapacity(file.data.count + 2_048)
        appendField("name", draft.name, boundary: boundary, to: &body)
        appendField("category", draft.category.rawValue, boundary: boundary, to: &body)
        if let cardNumber = draft.cardNumber {
            appendField("cardNumber", cardNumber, boundary: boundary, to: &body)
        }

        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"upload.\(file.format.fileExtension)\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: \(file.format.mediaType)\r\n\r\n".utf8)
        body.append(file.data)
        body.append(contentsOf: "\r\n--\(boundary)--\r\n".utf8)

        return try await client.sendMultipart(path, method: method, body: body, boundary: boundary, token: token)
    }

    private func appendField(_ name: String, _ value: String, boundary: String, to data: inout Data) {
        data.append(contentsOf: "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".utf8)
    }
}
