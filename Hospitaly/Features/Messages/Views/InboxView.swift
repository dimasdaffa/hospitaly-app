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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: -Theme.heroOverlap) {
                    header
                        .hospitalyPageHero(topInset: geometry.safeAreaInsets.top)

                    VStack(alignment: .leading, spacing: 14) {
                        searchBar
                        content
                    }
                    .padding(.horizontal, Theme.contentInset)
                    .frame(maxWidth: Theme.dashboardWidth)
                    .padding(.bottom, 12)
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .pullToRefresh(isEnabled: canPullToRefresh) { await refresh() }
            .ignoresSafeArea(.container, edges: .top)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .toolbarVisibility(.hidden, for: .navigationBar)
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
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Messages")
                .font(.largeTitle.bold())
                .tracking(-0.8)
                .foregroundStyle(Color.themeSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showsCompose = true
            } label: {
                Label("New Message", systemImage: "square.and.pencil")
                    .labelStyle(.iconOnly)
                    .font(.headline)
                    .foregroundStyle(Color.themeSurface)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(Color.themeCrimsonDeep.opacity(0.35)).interactive(), in: Circle())
                    .environment(\.colorScheme, .dark)
            }
            .buttonStyle(.plain)
        }
    }

    private var searchBar: some View {
        @Bindable var model = model

        return HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.themeCrimsonInk)

            TextField("Search doctor or message", text: $model.query)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(Color.themeText)

            if !model.query.isEmpty {
                Button {
                    model.query = ""
                } label: {
                    Label("Clear Search", systemImage: "xmark.circle.fill")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Color.themeSecondaryText)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .frame(minHeight: Theme.heroOverlap * 2)
        .hospitalyGlassSurface(in: Capsule())
        .environment(\.colorScheme, .light)
    }

    @ContentBuilder
    private var content: some View {
        let searching = !model.searchTerm.isEmpty
        let hasCurrentResults = model.resultQuery == model.searchTerm
        let rows = searching ? (hasCurrentResults ? model.searchResults : []) : model.conversations
        let phase = searching && !hasCurrentResults
            ? .loading : (searching ? model.searchPhase : model.phase)

        switch phase {
        case .loading:
            LoadingStateView(searching ? "Searching…" : "Loading messages…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, rows.isEmpty ? 40 : 6)
            if !rows.isEmpty { list(rows) }
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
                RefreshFailureView(message: message, onRetry: retry)
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

    private var canPullToRefresh: Bool {
        let phase = model.searchTerm.isEmpty ? model.phase : model.searchPhase
        return isActive && phase != .loading
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
