//
//  DocumentDraft.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

struct DocumentDraft {
    let name: String
    let cardNumber: String?
    let category: DocumentCategory
    let file: UploadDocumentFile?

    func matches(_ document: PatientDocument) -> Bool {
        guard document.name == name, document.cardNumber == cardNumber, document.category == category else { return false }
        guard let file else { return true }
        return document.size == file.data.count && document.mediaType == file.format.mediaType
    }
}
