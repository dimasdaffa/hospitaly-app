//
//  DocumentsViewModel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation
import Observation

@Observable
final class DocumentsViewModel {
    enum Phase: Equatable {
        case loading, loaded, failed(String)
    }

    private(set) var documents: [PatientDocument] = []
    private(set) var phase = Phase.loading
    private(set) var deletingID: UUID?
    @ObservationIgnored private var requestID: UUID?

    var insurance: [PatientDocument] { documents.filter { $0.category.isInsurance } }
    var otherDocuments: [PatientDocument] { documents.filter { !$0.category.isInsurance } }

    func load(using request: @MainActor () async throws -> [PatientDocument]) async {
        guard !Task.isCancelled else { return }
        let id = UUID()
        requestID = id
        if documents.isEmpty { phase = .loading }

        do {
            let rows = try await request()
            try Task.checkCancellation()
            guard requestID == id else { return }
            replace(with: rows)
        } catch where !Task.isCancelled && !(error is CancellationError) {
            guard requestID == id else { return }
            phase = .failed(error.localizedDescription)
        } catch {
            return
        }
    }

    func replace(with rows: [PatientDocument]) {
        requestID = nil
        documents = rows
        phase = .loaded
    }

    func upsert(_ document: PatientDocument) {
        replace(with: [document] + documents.filter { $0.id != document.id })
    }

    func delete(_ document: PatientDocument, using actions: DocumentsActions) async -> String? {
        guard deletingID == nil, document.canManage, !Task.isCancelled else { return nil }
        deletingID = document.id
        defer { deletingID = nil }

        do {
            try await actions.delete(document.id)
            replace(with: documents.filter { $0.id != document.id })
        } catch APIError.httpStatus(401) {
            return nil
        } catch APIError.httpStatus(409) {
            return "This file is linked to a published lab result."
        } catch where !Task.isCancelled && !(error is CancellationError) {
            if let rows = try? await actions.load(), !Task.isCancelled {
                replace(with: rows)
                if !rows.contains(where: { $0.id == document.id }) { return nil }
            }
            return error.localizedDescription
        } catch {
            return nil
        }
        return nil
    }
}
