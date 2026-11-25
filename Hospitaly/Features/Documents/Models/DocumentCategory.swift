//
//  DocumentCategory.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

enum DocumentCategory: String, Decodable, CaseIterable, Identifiable, Sendable {
    case bpjs
    case insurance
    case familyCard
    case idCard
    case other
    case clinicalAttachment

    static var uploadCategories: [Self] {
        allCases.filter { $0 != .clinicalAttachment }
    }

    var id: Self { self }
    var isInsurance: Bool { self == .bpjs || self == .insurance }

    var title: String {
        switch self {
        case .bpjs: "BPJS Kesehatan"
        case .insurance: "Other Insurance"
        case .familyCard: "Kartu Keluarga (KK)"
        case .idCard: "KTP (ID Card)"
        case .other: "Other Documents"
        case .clinicalAttachment: "Clinical Attachment"
        }
    }

    var icon: String {
        switch self {
        case .bpjs, .insurance: "cross.case.fill"
        case .familyCard: "person.2.fill"
        case .idCard: "person.text.rectangle.fill"
        case .other: "folder.fill"
        case .clinicalAttachment: "doc.text.fill"
        }
    }
}
