//
//  InboxView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct InboxView: View {
    private struct SearchRequest: Equatable {
        let term: String
        let isActive: Bool
        let retry: Int
    }

    @State private var searchRetry = 0
    @State private var showsCompose = false
    @State private var selectedPeer: MessagePeer?

    let model: InboxViewModel
    let patientID: UUID
    let isActive: Bool
    let actions: MessageActions
    let loadDoctors: @MainActor () async throws -> [Doctor]
    let onOpenPeer: (MessagePeer) -> Void

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: 540)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Message", systemImage: "square.and.pencil") { showsCompose = true }
            }
        }
        .searchable(text: $model.query, prompt: "Search doctor or message")
        .sheet(isPresented: $showsCompose, onDismiss: openSelectedPeer) {
            NavigationStack {
                MessageDoctorPickerView(loadDoctors: loadDoctors, patientID: patientID) { peer in
                    selectedPeer = peer
                    showsCompose = false
                }
            }
            .tint(Color.themePrimary)
        }
        .task(id: isActive) {
            guard isActive else { return }
            await model.load(using: actions.loadInbox)
        }
        .task(id: SearchRequest(term: model.searchTerm, isActive: isActive, retry: searchRetry)) {
            guard isActive else { return }
            await model.search(using: actions.loadInbox)
        }
        .refreshable { await refresh() }
    }

    @ContentBuilder
    private var content: some View {
        let searching = !model.searchTerm.isEmpty
        let rows = searching ? model.searchResults : model.conversations
        let phase = searching && model.resultQuery != model.searchTerm
            ? .loading : (searching ? model.searchPhase : model.phase)

        switch phase {
        case .loading:
            ProgressView(searching ? "Searching…" : "Loading messages…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        case .failed(let message):
            if rows.isEmpty {
                ContentUnavailableView {
                    Label("Couldn’t Load Messages", systemImage: "exclamationmark.bubble")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry", action: retry)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.themeSecondaryText)
                    Button("Retry", action: retry)
                        .font(.footnote.weight(.semibold))
                }
                .padding(.vertical, 10)
                list(rows)
            }
        case .loaded:
            if rows.isEmpty {
                if searching {
                    ContentUnavailableView(
                        "No Matching Messages", systemImage: "magnifyingglass",
                        description: Text("Try searching for a different name or message.")
                    )
                } else {
                    ContentUnavailableView {
                        Label("No Conversations", systemImage: "bubble.left.and.bubble.right")
                    } description: {
                        Text("Messages with your doctors will appear here.")
                    } actions: {
                        Button("New Message") { showsCompose = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                list(rows)
            }
        }
    }

    private func list(_ rows: [Conversation]) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(rows) { conversation in
                NavigationLink(value: conversation.peer) {
                    ConversationRow(conversation: conversation, patientID: patientID)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }

    private func refresh() async {
        if model.searchTerm.isEmpty {
            await model.load(using: actions.loadInbox)
        } else {
            await model.search(using: actions.loadInbox)
        }
    }

    private func retry() {
        if model.searchTerm.isEmpty {
            Task { await refresh() }
        } else {
            searchRetry += 1
        }
    }

    private func openSelectedPeer() {
        guard let selectedPeer else { return }
        self.selectedPeer = nil
        onOpenPeer(selectedPeer)
    }
}

#Preview("Inbox") {
    NavigationStack {
        InboxView(
            model: InboxViewModel(), patientID: MessagePeer.samplePatientID, isActive: true,
            actions: .preview, loadDoctors: { [.messageSample] }, onOpenPeer: { _ in }
        )
    }
    .tint(Color.themePrimary)
}

#Preview("Empty Inbox") {
    NavigationStack {
        InboxView(
            model: InboxViewModel(), patientID: MessagePeer.samplePatientID, isActive: true,
            actions: .emptyPreview, loadDoctors: { [] }, onOpenPeer: { _ in }
        )
    }
    .tint(Color.themePrimary)
}
