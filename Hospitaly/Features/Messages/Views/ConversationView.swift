//
//  ConversationView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct ConversationView: View {
    @State private var model: ConversationViewModel

    let actions: MessageActions
    let onInboxChanged: @MainActor () async -> Void

    init(
        peer: MessagePeer, patientID: UUID, actions: MessageActions,
        onInboxChanged: @escaping @MainActor () async -> Void
    ) {
        _model = State(initialValue: ConversationViewModel(peer: peer, patientID: patientID))
        self.actions = actions
        self.onInboxChanged = onInboxChanged
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if !model.hasLoaded {
                        initialState
                    } else {
                        if model.isLoading && !model.isLoadingEarlier {
                            LoadingStateView("Refreshing conversation…")
                                .frame(maxWidth: .infinity)
                        }

                        if let error = model.loadError {
                            retryRow(error) { await refresh() }
                        }

                        if model.messages.isEmpty {
                            ContentUnavailableView(
                                "No Messages Yet", systemImage: "bubble.left",
                                description: Text("Send a message to start the conversation.")
                            )
                        } else {
                            earlierMessages(reader)
                            ForEach(model.messages) { message in
                                bubble(message)
                                    .id(message.id)
                            }
                        }

                        if let error = model.readError {
                            retryRow(error) { await model.markUnread(using: actions, onChange: onInboxChanged) }
                        }
                    }
                }
                .frame(maxWidth: 540)
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages.last?.id, initial: true) { _, id in
                if let id { reader.scrollTo(id, anchor: .bottom) }
            }
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle(model.peer.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) { header }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh Conversation", systemImage: "arrow.clockwise") {
                    Task { await refresh() }
                }
                .disabled(model.isSending || model.isLoading || model.isMarkingRead)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        .refreshable { await refresh() }
        .task { await refresh() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            MessageAvatar(peer: model.peer, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(model.peer.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let specialty = model.peer.specialty {
                    Text(specialty)
                        .font(.caption2)
                        .foregroundStyle(Color.themeSecondaryText)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(Color.themeText)
        }
    }

    @ContentBuilder
    private var initialState: some View {
        if let error = model.loadError {
            ContentUnavailableView {
                Label("Couldn’t Load Conversation", systemImage: "exclamationmark.bubble")
            } description: {
                Text(error)
            } actions: {
                Button("Retry") { Task { await refresh() } }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            LoadingStateView("Loading conversation…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 38)
        }
    }

    @ContentBuilder
    private func earlierMessages(_ reader: ScrollViewProxy) -> some View {
        if model.isLoadingEarlier {
            LoadingStateView("Loading earlier messages…")
                .font(.footnote)
                .frame(maxWidth: .infinity)
        } else if model.hasEarlier {
            Button(model.earlierError == nil ? "Load Earlier Messages" : "Retry Earlier Messages") {
                let previousFirst = model.messages.first?.id
                Task {
                    let inserted = await model.loadEarlier(using: actions, onChange: onInboxChanged)
                    if inserted, let previousFirst { reader.scrollTo(previousFirst, anchor: .top) }
                }
            }
            .font(.footnote.weight(.semibold))
            .frame(maxWidth: .infinity)
            .disabled(model.isSending || model.isLoading || model.isMarkingRead)

            if let error = model.earlierError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func bubble(_ message: Message) -> some View {
        let outgoing = message.senderId == model.patientID
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 18, bottomLeadingRadius: outgoing ? 18 : 6,
            bottomTrailingRadius: outgoing ? 6 : 18, topTrailingRadius: 18
        )

        return VStack(alignment: outgoing ? .trailing : .leading, spacing: 4) {
            Text(message.content)
                .font(.subheadline)
                .foregroundStyle(outgoing ? Color.themeSurface : .themeText)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    if outgoing {
                        shape.fill(Theme.crimsonGradient)
                    } else {
                        shape.fill(Color.themeSurface)
                    }
                }

            if let date = message.createdAt {
                Text(messageDate(date))
                    .font(.caption2)
                    .foregroundStyle(Color.themeSecondaryText)
                    .padding(.horizontal, 3)
            }
        }
        .padding(outgoing ? .leading : .trailing, 44)
        .frame(maxWidth: .infinity, alignment: outgoing ? .trailing : .leading)
    }

    private func messageDate(_ date: Date) -> String {
        if ClinicDate.calendar.isDateInToday(date) { return ClinicDate.time(date) }
        return ClinicDate.label(date, as: .dateTime.month(.abbreviated).day().hour().minute())
    }

    private var composer: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: 8) {
            if let error = model.sendError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.themePrimary)

                if model.needsHistoryCheck {
                    Button("Check Conversation") { Task { await refresh() } }
                        .font(.footnote.weight(.semibold))
                        .disabled(model.isLoading || model.isMarkingRead)
                }
            }

            HStack(alignment: .bottom, spacing: 10) {
                TextField("Write a message…", text: $model.draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 10)
                    .foregroundStyle(Color.themeText)
                    .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 18))
                    .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(Color.themeGlassRose) }
                    .disabled(model.isSending || model.needsHistoryCheck)

                Button {
                    Task { await model.send(using: actions, onChange: onInboxChanged) }
                } label: {
                    Group {
                        if model.isSending {
                            ProgressView()
                                .tint(.themeSurface)
                        } else {
                            Label("Send", systemImage: "arrow.up")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.themeSurface)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(model.canSend || model.isSending ? Color.themeCrimsonInk : .themeMutedText, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(!model.canSend)
            }

            if model.characterCount >= 235 {
                Text("\(model.characterCount)/\(MessageService.characterLimit)")
                    .font(.caption2)
                    .foregroundStyle(model.characterCount > MessageService.characterLimit ? Color.themePrimary : .themeSecondaryText)
            }
        }
        .frame(maxWidth: 540)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .hospitalyActionBar()
        .overlay(alignment: .top) { Divider() }
    }

    private func retryRow(_ error: String, retry: @escaping @MainActor () async -> Void) -> some View {
        HStack {
            Text(error)
                .foregroundStyle(Color.themeSecondaryText)
            Spacer(minLength: 8)
            Button("Retry") { Task { await retry() } }
                .disabled(model.isLoading || model.isMarkingRead)
        }
        .font(.footnote)
    }

    private func refresh() async {
        await model.loadLatest(using: actions, onChange: onInboxChanged)
    }
}

#Preview("Conversation") {
    NavigationStack {
        ConversationView(peer: .sample, patientID: MessagePeer.samplePatientID, actions: .preview, onInboxChanged: {})
    }
    .tint(Color.themePrimary)
}

#Preview("New Conversation") {
    NavigationStack {
        ConversationView(peer: .sample, patientID: MessagePeer.samplePatientID, actions: .emptyPreview, onInboxChanged: {})
    }
    .tint(Color.themePrimary)
}
