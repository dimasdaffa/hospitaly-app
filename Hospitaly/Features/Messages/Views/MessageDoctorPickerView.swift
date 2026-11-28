//
//  MessageDoctorPickerView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct MessageDoctorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearching: Bool
    @State private var peers: [MessagePeer] = []
    @State private var phase = InboxViewModel.Phase.loading
    @State private var query = ""
    @State private var retry = 0

    let loadDoctors: @MainActor () async throws -> [Doctor]
    let patientID: UUID
    let onSelect: (MessagePeer) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                VStack(spacing: -Theme.heroOverlap) {
                    header
                    searchBar
                        .padding(.horizontal, 14)
                }
                .padding(.bottom, 6)

                content
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("New Message")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .task(id: retry) { await load() }
    }

    private var header: some View {
        Label("Choose a Doctor", systemImage: "square.and.pencil")
            .font(.title2.bold())
            .foregroundStyle(Color.themeSurface)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, Theme.heroOverlap + 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                CrimsonHeaderBackdrop().clipShape(.rect(cornerRadius: Theme.cardRadius))
            }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.themeCrimsonInk)

            TextField("Search doctor or specialty", text: $query)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isSearching)
                .onSubmit { isSearching = false }
                .foregroundStyle(Color.themeText)

            if !query.isEmpty {
                Button {
                    query = ""
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

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            LoadingStateView("Loading doctors…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn’t Load Doctors", systemImage: "exclamationmark.circle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { retry += 1 }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded:
            results
        }
    }

    @ContentBuilder
    private var results: some View {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = peers.filter { peer in
            term.isEmpty || peer.name.localizedStandardContains(term) ||
                (peer.specialty?.localizedStandardContains(term) ?? false)
        }

        if peers.isEmpty {
            ContentUnavailableView(
                "No Doctors Available for Messaging", systemImage: "stethoscope",
                description: Text("Doctors with a linked account will appear here.")
            )
        } else if matches.isEmpty {
            ContentUnavailableView.search(text: term)
        } else {
            ForEach(matches) { peer in
                doctorRow(peer)
            }
        }
    }

    private func doctorRow(_ peer: MessagePeer) -> some View {
        Button {
            onSelect(peer)
        } label: {
            HStack(spacing: 12) {
                MessageAvatar(peer: peer, size: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(peer.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    if let specialty = peer.specialty, !specialty.isEmpty {
                        Text(specialty)
                            .font(.subheadline)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.themeCrimsonInk)
            }
            .padding(14)
            .hospitalyPanel(cornerRadius: 20)
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        phase = .loading
        do {
            let doctors = try await loadDoctors()
            try Task.checkCancellation()
            var seen: Set<UUID> = [patientID]
            peers = doctors.compactMap(MessagePeer.init(doctor:)).filter { seen.insert($0.id).inserted }
            phase = .loaded
        } catch where !Task.isCancelled && !(error is CancellationError) {
            phase = .failed(error.localizedDescription)
        } catch {
            return
        }
    }
}

#Preview("Choose a Doctor") {
    NavigationStack {
        MessageDoctorPickerView(loadDoctors: { [.messageSample] }, patientID: MessagePeer.samplePatientID, onSelect: { _ in })
    }
}

#Preview("No Doctors") {
    NavigationStack {
        MessageDoctorPickerView(loadDoctors: { [] }, patientID: MessagePeer.samplePatientID, onSelect: { _ in })
    }
}

#Preview("Request Failed") {
    NavigationStack {
        MessageDoctorPickerView(
            loadDoctors: { throw APIError.connectionFailed },
            patientID: MessagePeer.samplePatientID,
            onSelect: { _ in }
        )
    }
}
