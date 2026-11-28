//
//  DocumentHistoryView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct DocumentHistoryView: View {
    @State private var model = DocumentsViewModel()
    @State private var loadAttempt = 0
    @State private var download: PrivateDocumentDownload?

    let actions: DocumentsActions

    var body: some View {
        Group {
            switch model.phase {
            case .loading:
                ProgressView("Loading history…")
            case .failed(let message):
                if model.documents.isEmpty {
                    ContentUnavailableView {
                        Label("Couldn’t Load History", systemImage: "exclamationmark.circle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry") { loadAttempt += 1 }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    history(loadError: message)
                }
            case .loaded:
                if model.documents.isEmpty {
                    ContentUnavailableView(
                        "No Document History", systemImage: "clock.arrow.circlepath",
                        description: Text("Uploaded and deleted documents will appear here.")
                    )
                } else {
                    history()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Document History")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(PrivateFileExportModifier(file: $download, download: actions.download))
        .task(id: loadAttempt) { await model.load(using: actions.loadHistory) }
        .refreshable { await model.load(using: actions.loadHistory) }
    }

    private func history(loadError: String? = nil) -> some View {
        let active = model.documents.filter { $0.deletedAt == nil }
        let deleted = model.documents.filter { $0.deletedAt != nil }

        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let loadError {
                    HStack(alignment: .firstTextBaseline) {
                        Text(loadError)
                            .foregroundStyle(Color.themeSecondaryText)
                        Spacer()
                        Button("Retry") { loadAttempt += 1 }
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                    .padding(14)
                    .hospitalyPanel()
                }

                if !active.isEmpty { documentGroup("Active", documents: active) }
                if !deleted.isEmpty { documentGroup("Deleted", documents: deleted) }
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private func documentGroup(_ title: LocalizedStringKey, documents: [PatientDocument]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)

            VStack(spacing: 0) {
                ForEach(documents) { document in
                    if document.id != documents.first?.id {
                        Rectangle()
                            .fill(Color.themeDivider)
                            .frame(height: 1)
                            .padding(.leading, 64)
                    }

                    if document.deletedAt == nil, let file = document.download {
                        Button {
                            download = file
                        } label: {
                            row(document)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(download != nil)
                    } else {
                        row(document)
                    }
                }
            }
            .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        }
    }

    private func row(_ document: PatientDocument) -> some View {
        HStack(spacing: 12) {
            DocumentCategoryIcon(category: document.category)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeText)
                Text(document.category.title)
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
                if let timelineLabel = timelineLabel(document) {
                    Text(timelineLabel)
                        .font(.caption2)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if download?.source == .document(document.id) {
                ProgressView()
            } else if document.download != nil {
                Image(systemName: "arrow.down.to.line")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themePrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func timelineLabel(_ document: PatientDocument) -> String? {
        if let deletedAt = document.deletedAt { return "Deleted \(dateLabel(deletedAt))" }
        if let updatedAt = document.updatedAt, updatedAt != document.createdAt {
            return "Updated \(dateLabel(updatedAt))"
        }
        return document.createdAt.map { "Uploaded \(dateLabel($0))" }
    }

    private func dateLabel(_ date: Date) -> String {
        ClinicDate.label(date, as: .dateTime.day().month(.abbreviated).year())
    }
}

#Preview("Active and Deleted Documents") {
    NavigationStack {
        DocumentHistoryView(actions: .preview)
    }
    .tint(Color.themePrimary)
}

#Preview("Empty History") {
    NavigationStack {
        DocumentHistoryView(actions: .emptyPreview)
    }
    .tint(Color.themePrimary)
}
