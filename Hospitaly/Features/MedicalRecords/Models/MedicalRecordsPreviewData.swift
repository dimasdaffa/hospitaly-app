//
//  MedicalRecordsPreviewData.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import Foundation

extension MedicalRecord {
    static let sample = MedicalRecord(
        id: UUID(),
        appointment: Visit(date: ClinicDate.dayString(.now), time: "10:00", doctor: sampleDoctor),
        diagnosis: "Sample consultation",
        symptoms: "Symptoms recorded at a demo visit.",
        treatment: "Care plan discussed during the consultation.",
        prescription: nil,
        notes: "Training record with synthetic data.",
        followUpRequired: true,
        followUpDate: nil,
        recordType: "diagnosis",
        severity: "moderate",
        symptomTags: ["Demo symptom"],
        medications: [Medication(
            id: UUID(), name: "Demo Medication", dose: "Dose recorded by staff",
            category: nil, instructions: "See the original prescription.", times: ["14:00"]
        )],
        createdAt: .now
    )

    static let sampleVaccination = MedicalRecord(
        id: UUID(), appointment: nil, diagnosis: "Demo vaccination", symptoms: "",
        treatment: "Vaccination registered in the training environment.", prescription: nil,
        notes: nil, followUpRequired: false, followUpDate: nil, recordType: "vaccination",
        severity: nil, symptomTags: nil, medications: nil, createdAt: .now.addingTimeInterval(-35 * 86_400)
    )

    private static let sampleDoctor = DoctorResponse(
        id: UUID(), name: "Dr. Sample", specialty: "General Practice", experience: 0, rating: 0,
        bio: nil, license: nil, totalPatients: 0, avatarURL: nil, reviewCount: nil, practice: nil,
        isFavorite: nil, nextAvailable: nil, userId: nil, user: DoctorResponse.Account(id: MessagePeer.sample.id)
    )
}

extension LabResult {
    static let sample = LabResult(
        id: UUID(),
        title: "Demo Lab Panel",
        laboratory: "RS Permata Sehat Lab",
        collectedAt: .now.addingTimeInterval(-3 * 86_400),
        alert: "Sample report flagged for review by the care team.",
        panels: [Panel(
            name: "Sample Panel", status: "elevated", summary: "Example lab summary entered by staff.",
            measurements: [
                Measurement(name: "Sample A", value: "123", unit: "units", referenceRange: "45–100", status: "elevated"),
                Measurement(name: "Sample B", value: "17", unit: "units", referenceRange: nil, status: nil)
            ]
        )],
        doctorNote: "Follow-up discussed in a demo consultation.",
        authorName: "Dr. Sample",
        authorSpecialty: "General Practice",
        pdfPath: "/api/lab-results/example/pdf"
    )

    static let emptySample = LabResult(
        id: UUID(), title: "Demo Lab Report", laboratory: "RS Permata Sehat Lab",
        collectedAt: .now, alert: nil, panels: [], doctorNote: nil,
        authorName: nil, authorSpecialty: nil, pdfPath: nil
    )
}

extension MedicalRecordsActions {
    static let preview = makePreview(isEmpty: false)
    static let previewEmpty = makePreview(isEmpty: true)

    private static func makePreview(isEmpty: Bool) -> MedicalRecordsActions {
        let attachment = RecordAttachment(
            id: UUID(), name: "Demo report.pdf", mediaType: "application/pdf", size: 1_024,
            createdAt: .now, downloadPath: "/api/documents/example/download"
        )
        let doctorService = DoctorService(client: APIClient(baseURL: URL(filePath: "/preview")))

        return MedicalRecordsActions(
            loadHistory: { isEmpty ? [] : [.record(.sample), .lab(.sample), .record(.sampleVaccination)] },
            loadRecord: { $0 == MedicalRecord.sampleVaccination.id ? .sampleVaccination : .sample },
            loadAttachments: { _ in isEmpty ? [] : [attachment] },
            loadLab: { _ in isEmpty ? .emptySample : .sample },
            download: { _ in throw APIError.httpStatus(404) },
            displayDoctor: { doctorService.displayDoctor($0) }
        )
    }
}
