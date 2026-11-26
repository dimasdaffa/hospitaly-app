//
//  MessageDoctorPickerView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct MessageDoctorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var peers: [MessagePeer] = []
    @State private var phase = InboxViewModel.Phase.loading
    @State private var query = ""
    @State private var retry = 0

    let loadDoctors: @MainActor () async throws -> [Doctor]
    let patientID: UUID
    let onSelect: (MessagePeer) -> Void

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView("Loading doctors…")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("New Message")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .searchable(text: $query, prompt: "Search doctors")
        .task(id: retry) { await load() }
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
            List(matches) { peer in
                Button {
                    onSelect(peer)
                } label: {
                    HStack(spacing: 12) {
                        MessageAvatar(peer: peer, size: 42)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(peer.name)
                                .font(.headline)
                                .foregroundStyle(Color.themeText)
                            if let specialty = peer.specialty {
                                Text(specialty)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.themeSecondaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .environment(\.colorScheme, .light)
        }
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

#Preview {
    NavigationStack {
        MessageDoctorPickerView(loadDoctors: { [.messageSample] }, patientID: MessagePeer.samplePatientID, onSelect: { _ in })
    }
}

#Preview("No Doctors") {
    NavigationStack {
        MessageDoctorPickerView(loadDoctors: { [] }, patientID: MessagePeer.samplePatientID, onSelect: { _ in })
    }
}
