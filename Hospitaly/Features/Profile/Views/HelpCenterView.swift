//
//  HelpCenterView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import Foundation
import SwiftUI

struct HelpCenterView: View {
    @State private var topics: [HelpTopic]?
    @State private var loadError: String?
    @State private var loadAttempt = 0

    let loadTopics: @MainActor () async throws -> [HelpTopic]

    var body: some View {
        Group {
            if let topics, !topics.isEmpty {
                List(topics, id: \.self) { topic in
                    DisclosureGroup(topic.title) {
                        Text(topic.answer)
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                            .padding(.vertical, 6)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .environment(\.colorScheme, .light)
            } else if let loadError {
                ContentUnavailableView {
                    Label("Couldn’t Load Help Topics", systemImage: "exclamationmark.circle")
                } description: {
                    Text(loadError)
                } actions: {
                    Button("Retry") { loadAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                }
            } else if topics != nil {
                ContentUnavailableView(
                    "No Help Topics", systemImage: "questionmark.circle",
                    description: Text("Hospital help topics will appear here.")
                )
            } else {
                ProgressView("Loading help topics…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: loadAttempt) { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        loadError = nil
        topics = nil
        do {
            let result = try await loadTopics()
            try Task.checkCancellation()
            var seen: Set<HelpTopic> = []
            topics = result.filter { seen.insert($0).inserted }
        } catch where !Task.isCancelled && !(error is CancellationError) {
            loadError = error.localizedDescription
        } catch {
            return
        }
    }
}

#Preview("Help Topics") {
    NavigationStack {
        HelpCenterView(loadTopics: ProfileSettingsActions.preview.loadHelp)
    }
}

#Preview("Empty Help Center") {
    NavigationStack {
        HelpCenterView(loadTopics: { [] })
    }
}
