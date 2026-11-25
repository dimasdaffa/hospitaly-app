//
//  DocumentUpload.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

struct DocumentUpload {
    let name: String
    let cardNumber: String?
    let category: DocumentCategory
    let file: UploadDocumentFile

    func matches(_ document: PatientDocument) -> Bool {
        document.name == name && document.cardNumber == cardNumber && document.category == category &&
            document.size == file.data.count && document.mediaType == file.format.mediaType
    }
}
