//
//  DocumentService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation

struct DocumentService {
    let client: APIClient

    func list(token: String) async throws -> [PatientDocument] {
        try await client.get("api/documents", token: token)
    }

    func upload(_ upload: DocumentUpload, token: String) async throws -> PatientDocument {
        let boundary = "Hospitaly-\(UUID().uuidString)"
        let file = upload.file
        var body = Data()
        body.reserveCapacity(file.data.count + 2_048)
        appendField("name", upload.name, boundary: boundary, to: &body)
        appendField("category", upload.category.rawValue, boundary: boundary, to: &body)
        if let cardNumber = upload.cardNumber {
            appendField("cardNumber", cardNumber, boundary: boundary, to: &body)
        }

        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"upload.\(file.format.fileExtension)\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: \(file.format.mediaType)\r\n\r\n".utf8)
        body.append(file.data)
        body.append(contentsOf: "\r\n--\(boundary)--\r\n".utf8)

        return try await client.postMultipart("api/documents", body: body, boundary: boundary, token: token)
    }

    func download(_ file: PrivateDocumentDownload, token: String) async throws -> Data {
        try await client.getFile(file, token: token)
    }

    private func appendField(_ name: String, _ value: String, boundary: String, to data: inout Data) {
        data.append(contentsOf: "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".utf8)
    }
}
