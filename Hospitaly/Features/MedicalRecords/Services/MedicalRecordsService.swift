//
//  MedicalRecordsService.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct MedicalRecordsService {
    let client: APIClient

    func history(token: String) async throws -> [MedicalRecordEntry] {
        async let records = self.records(token: token)
        async let labs = self.labs(token: token)
        let (recordRows, labRows) = try await (records, labs)
        return recordRows.map(MedicalRecordEntry.record) + labRows.map(MedicalRecordEntry.lab)
    }

    func record(_ id: UUID, token: String) async throws -> MedicalRecord {
        try await client.get("api/medical-records/\(id)", token: token)
    }

    func attachments(_ id: UUID, token: String) async throws -> [RecordAttachment] {
        try await client.get("api/medical-records/\(id)/documents", token: token)
    }

    func lab(_ id: UUID, token: String) async throws -> LabResult {
        try await client.get("api/lab-results/\(id)", token: token)
    }

    func download(_ file: PrivateDocumentDownload, token: String) async throws -> Data {
        try await client.getFile(file, token: token)
    }

    private func records(token: String) async throws -> [MedicalRecord] {
        try await client.get("api/medical-records", token: token)
    }

    private func labs(token: String) async throws -> [LabResult] {
        try await client.get("api/lab-results", token: token)
    }
}
