//
//  DocumentsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct DocumentsView: View {
    private enum Route: Hashable {
        case history
    }

    private enum Form: Identifiable {
        case upload
        case edit(PatientDocument)

        var id: String { document?.id.uuidString ?? "new" }

        var document: PatientDocument? {
            if case .edit(let document) = self { return document }
            return nil
        }
    }

    @State private var model = DocumentsViewModel()
    @State private var form: Form?
    @State private var deleteCandidate: PatientDocument?
    @State private var deleteError: String?
    @State private var loadAttempt = 0
    @State private var download: PrivateDocumentDownload?

    let actions: DocumentsActions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .frame(maxWidth: 540)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color.themeDetailCanvas.ignoresSafeArea())
        .navigationTitle("Documents & BPJS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("History", value: Route.history)
                    .disabled(isBusy)
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .history: DocumentHistoryView(actions: actions)
            }
        }
        .sheet(item: $form) { form in
            NavigationStack {
                UploadDocumentView(
                    actions: actions, knownIDs: Set(model.documents.map(\.id)),
                    original: form.document, onRefresh: model.replace(with:), onSaved: model.upsert(_:)
                )
            }
            .tint(Color.themePrimary)
        }
        .alert("Delete Document?", item: $deleteCandidate) { document in
            Button("Delete", role: .destructive) {
                Task { deleteError = await model.delete(document, using: actions) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { document in
            Text("The file for “\(document.name)” will be deleted. Its details will stay in History.")
        }
        .alert("Couldn’t Delete Document", item: $deleteError) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .modifier(PrivateFileExportModifier(file: $download, download: actions.download))
        .task(id: loadAttempt) { await model.load(using: actions.load) }
        .refreshable { await model.load(using: actions.load) }
    }

    private var isBusy: Bool { download != nil || model.deletingID != nil }

    @ContentBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView("Loading documents…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
        case .failed(let message):
            if model.documents.isEmpty {
                ContentUnavailableView {
                    Label("Couldn’t Load Documents", systemImage: "exclamationmark.circle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Retry") { loadAttempt += 1 }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                HStack {
                    Text(message)
                        .foregroundStyle(Color.themeSecondaryText)
                    Spacer()
                    Button("Retry") { loadAttempt += 1 }
                        .fontWeight(.semibold)
                }
                .font(.footnote)
                sections
            }
        case .loaded:
            sections
        }
    }

    @ContentBuilder
    private var sections: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Insurance")

            if model.insurance.isEmpty {
                emptyRow("Your BPJS card and other insurance files will appear here.", symbol: "cross.case")
            } else {
                ForEach(model.insurance) { document in insuranceRow(document) }
            }
        }

        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Upload")
            uploadButton
        }

        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Recent Files")

            if model.otherDocuments.isEmpty {
                emptyRow("Your ID cards and supporting documents will appear here.", symbol: "folder")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(model.otherDocuments) { document in fileCard(document) }
                }
            }
        }
    }

    private var uploadButton: some View {
        Button {
            form = .upload
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.themePrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.themePrimary.opacity(0.08), in: Circle())

                Text("Upload New Document")
                    .font(.headline)
                    .foregroundStyle(Color.themeText)
                Text("PDF, JPEG, or PNG · up to 5 MiB")
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 140)
            .padding(10)
            .background(Color.themeSurface, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.themePrimary, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }

    private func insuranceRow(_ document: PatientDocument) -> some View {
        HStack(spacing: 12) {
            Button {
                download = document.download
            } label: {
                HStack(spacing: 12) {
                    DocumentCategoryIcon(category: document.category)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.themeText)
                        Text(document.cardNumber ?? document.category.title)
                            .font(.caption)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    downloadIcon(document)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(isBusy || document.download == nil)

            managementMenu(document)
        }
        .padding(14)
        .background(Color.themeSurface, in: .rect(cornerRadius: 17))
    }

    private func fileCard(_ document: PatientDocument) -> some View {
        Button {
            download = document.download
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    DocumentCategoryIcon(category: document.category, size: 43)
                    Spacer()
                    downloadIcon(document)
                }
                .padding(.trailing, document.canManage ? 32 : 0)

                Text(document.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeText)
                    .lineLimit(2)

                Text(document.category.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.themeSecondaryText)
                    .lineLimit(1)

                Text(fileDetails(document))
                    .font(.caption2)
                    .foregroundStyle(Color.themeSecondaryText)
                    .lineLimit(1)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 133, alignment: .topLeading)
            .background(Color.themeSurface, in: .rect(cornerRadius: 17))
            .overlay { RoundedRectangle(cornerRadius: 17).strokeBorder(Color.themeCardBorder) }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isBusy || document.download == nil)
        .overlay(alignment: .topTrailing) {
            managementMenu(document)
                .padding(9)
        }
    }

    @ContentBuilder
    private func managementMenu(_ document: PatientDocument) -> some View {
        if model.deletingID == document.id {
            ProgressView()
                .frame(width: 30, height: 32)
        } else if document.canManage {
            Menu {
                Button("Edit", systemImage: "pencil") { form = .edit(document) }
                Button("Delete", systemImage: "trash", role: .destructive) { deleteCandidate = document }
            } label: {
                Label("Document Actions", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeSecondaryText)
                    .frame(width: 30, height: 32)
                    .contentShape(.rect)
            }
            .disabled(isBusy)
        }
    }

    @ContentBuilder
    private func downloadIcon(_ document: PatientDocument) -> some View {
        if download?.source == .document(document.id) {
            ProgressView()
        } else if document.download != nil {
            Label("Download", systemImage: "arrow.down.to.line")
                .labelStyle(.iconOnly)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themePrimary)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.themeText)
    }

    private func emptyRow(_ message: String, symbol: String) -> some View {
        Label(message, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(Color.themeSecondaryText)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.themeSurface, in: .rect(cornerRadius: 17))
    }

    private func fileDetails(_ document: PatientDocument) -> String {
        let size = document.size.formatted(.byteCount(style: .file))
        guard let date = document.createdAt else { return size }
        return "\(size) · \(ClinicDate.label(date, as: .dateTime.month(.abbreviated).day()))"
    }
}

#Preview("Documents") {
    NavigationStack {
        DocumentsView(actions: .preview)
    }
}

#Preview("Empty Documents") {
    NavigationStack {
        DocumentsView(actions: .emptyPreview)
    }
}
