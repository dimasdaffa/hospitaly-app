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
    @State private var isLoading = false

    let loadTopics: @MainActor () async throws -> [HelpTopic]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                header
                status

                ForEach(topics ?? [], id: \.self) { topic in
                    topicCard(topic)
                }
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: loadAttempt) { await load() }
        .refreshable { await load() }
    }

    private var header: some View {
        Label("Frequently Asked Questions", systemImage: "questionmark.bubble")
            .font(.title2.bold())
            .foregroundStyle(Color.themeSurface)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                CrimsonHeaderBackdrop().clipShape(.rect(cornerRadius: Theme.cardRadius))
            }
    }

    @ViewBuilder
    private var status: some View {
        let hasTopics = topics?.isEmpty == false

        if isLoading || (topics == nil && loadError == nil) {
            LoadingStateView(hasTopics ? "Refreshing help topics…" : "Loading help topics…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, hasTopics ? 6 : 32)
        } else if let loadError {
            if hasTopics {
                RefreshFailureView(message: loadError) { loadAttempt += 1 }
            } else {
                ContentUnavailableView {
                    Label("Couldn’t Load Help Topics", systemImage: "exclamationmark.circle")
                } description: {
                    Text(loadError)
                } actions: {
                    Button("Retry") { loadAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                }
            }
        } else if !hasTopics {
            ContentUnavailableView {
                Label("No Help Topics", systemImage: "questionmark.circle")
            } description: {
                Text("Hospital help topics will appear here.")
            } actions: {
                Button("Refresh") { loadAttempt += 1 }
                    .buttonStyle(.bordered)
            }
        }
    }

    private func topicCard(_ topic: HelpTopic) -> some View {
        DisclosureGroup {
            Text(topic.answer)
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondaryText)
                .lineSpacing(3)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 12))
                .padding(.top, 8)
        } label: {
            Text(topic.title)
                .font(.headline)
                .foregroundStyle(Color.themeText)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .tint(Color.themeCrimsonInk)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .hospitalyPanel(cornerRadius: 20)
    }

    private func load() async {
        guard !isLoading, !Task.isCancelled else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await loadTopics()
            try Task.checkCancellation()
            var seen: Set<HelpTopic> = []
            topics = result.filter { seen.insert($0).inserted }
            loadError = nil
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

#Preview("Request Failed") {
    NavigationStack {
        HelpCenterView(loadTopics: { throw APIError.connectionFailed })
    }
}
