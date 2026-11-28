//
//  MedicalRecordsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct MedicalRecordsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model = MedicalRecordsViewModel()
    @State private var loadAttempt = 0

    let actions: MedicalRecordsActions
    let onFollowUp: (Doctor) -> Void
    var onChat: ((Doctor) -> Void)? = nil

    var body: some View {
        @Bindable var model = model

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                filters
                content
            }
            .frame(maxWidth: 540)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Medical Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .searchable(text: $model.query, prompt: "Search medical records")
        .navigationDestination(for: MedicalRecordEntry.Route.self, destination: destination)
        .task(id: loadAttempt) { await model.load(using: actions.loadHistory) }
        .refreshable { await model.load(using: actions.loadHistory) }
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterButton("All Records", kind: nil)
                ForEach(MedicalRecordEntry.Kind.allCases) { kind in
                    filterButton(kind.rawValue, kind: kind)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func filterButton(_ title: String, kind: MedicalRecordEntry.Kind?) -> some View {
        let selected = model.filter == kind
        return Button {
            model.filter = kind
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color.themeSurface : Color.themeSecondaryText)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .background(selected ? Color.themeCrimsonInk : Color.themeSurface.opacity(0.86), in: Capsule())
                .overlay { Capsule().strokeBorder(Color.themeOutline.opacity(selected ? 0 : 0.85)) }
        }
        .buttonStyle(.plain)
    }

    @ContentBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            LoadingStateView(model.entries.isEmpty ? "Loading medical records…" : "Refreshing medical records…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, model.entries.isEmpty ? 38 : 6)
        case .failed(let message):
            if model.entries.isEmpty {
                ContentUnavailableView {
                    Label("Couldn’t Load Records", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { loadAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                RefreshFailureView(message: message) { loadAttempt += 1 }
            }
        case .loaded:
            EmptyView()
        }

        if !model.entries.isEmpty || model.phase == .loaded {
            history
        }
    }

    @ContentBuilder
    private var history: some View {
        let latest = model.latestVisit
        let months = model.months

        if model.entries.isEmpty {
            ContentUnavailableView(
                "No Medical Records", systemImage: "folder",
                description: Text("Your diagnoses, vaccinations, and published lab results will appear here.")
            )
        } else if latest == nil && months.isEmpty {
            ContentUnavailableView(
                "No Matching Records", systemImage: "magnifyingglass",
                description: Text("Try a different keyword or select All Records.")
            )
        } else {
            if let latest {
                NavigationLink(value: latest.id) { latestCard(latest) }
                    .buttonStyle(.plain)
            }

            if !months.isEmpty {
                Text(latest == nil ? "Records" : "Past Records")
                    .font(.headline)
                    .foregroundStyle(Color.themeText)
            }

            ForEach(months) { month in
                VStack(alignment: .leading, spacing: 12) {
                    Text(month.title.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(0.6)
                        .foregroundStyle(Color.themeSecondaryText)

                    ForEach(month.entries) { entry in
                        NavigationLink(value: entry.id) { MedicalRecordCard(entry: entry) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func latestCard(_ entry: MedicalRecordEntry) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Last Visit")
                .font(.subheadline.weight(.medium))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.provider ?? entry.title)
                        .font(.title.bold())
                    Text(visitCaption(entry))
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSurface.opacity(0.85))
                }

                Spacer()

                Image(systemName: "doc.text.fill")
                    .font(.headline)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.18), in: .rect(cornerRadius: 12))
            }

            Rectangle().fill(.white.opacity(0.27)).frame(height: 1)

            HStack {
                Text("View Full Report")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color.themeSurface)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(Theme.crimsonGradient)
                .shadow(color: Color.themePrimary.opacity(0.19), radius: 6, y: 4)
        }
    }

    private func visitCaption(_ entry: MedicalRecordEntry) -> String {
        let date = entry.date.map { ClinicDate.label($0, as: .dateTime.day().month(.abbreviated).year()) }
        return [entry.subtitle, date].compactMap { $0 }.joined(separator: " • ")
    }

    @ContentBuilder
    private func destination(_ route: MedicalRecordEntry.Route) -> some View {
        switch route {
        case .record(let id):
            DiagnosisDetailView(recordID: id, actions: actions, onFollowUp: onFollowUp, onChat: onChat)
        case .lab(let id):
            LabResultDetailView(resultID: id, actions: actions)
        }
    }
}

#Preview("Medical Records") {
    NavigationStack {
        MedicalRecordsView(actions: .preview, onFollowUp: { _ in })
    }
    .tint(Color.themePrimary)
}

#Preview("Empty History") {
    NavigationStack {
        MedicalRecordsView(actions: .previewEmpty, onFollowUp: { _ in })
    }
    .tint(Color.themePrimary)
}
