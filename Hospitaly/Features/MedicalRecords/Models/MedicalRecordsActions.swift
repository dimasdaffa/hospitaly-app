//
//  MedicalRecordsActions.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

struct MedicalRecordsActions {
    let loadHistory: @MainActor () async throws -> [MedicalRecordEntry]
    let loadRecord: @MainActor (UUID) async throws -> MedicalRecord
    let loadAttachments: @MainActor (UUID) async throws -> [RecordAttachment]
    let loadLab: @MainActor (UUID) async throws -> LabResult
    let download: @MainActor (PrivateDocumentDownload) async throws -> Data
    let displayDoctor: @MainActor (DoctorResponse) -> Doctor
}
