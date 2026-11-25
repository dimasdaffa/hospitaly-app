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

    func add(_ document: PatientDocument) {
        replace(with: [document] + documents.filter { $0.id != document.id })
    }
}
