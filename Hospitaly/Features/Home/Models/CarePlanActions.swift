//
//  CarePlanActions.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct CarePlanActions {
    let load: @MainActor (String) async throws -> [CarePlanEntry]
    let markTaken: @MainActor (CarePlanEntry) async throws -> CarePlanEntry
}

extension CarePlanActions {
    static let preview = CarePlanActions(
        load: { _ in [.takenSample, .sample] },
        markTaken: { entry in
            var entry = entry
            entry.takenAt = .now
            return entry
        }
    )
}
