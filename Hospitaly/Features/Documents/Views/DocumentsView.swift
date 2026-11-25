//
//  DocumentsView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct DocumentsView: View {
    @State private var model = DocumentsViewModel()
    @State private var showsUpload = false
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
        .sheet(isPresented: $showsUpload) {
            NavigationStack {
                UploadDocumentView(
                    actions: actions, knownIDs: Set(model.documents.map(\.id)),
                    onRefresh: model.replace(with:), onSaved: model.add(_:)
                )
            }
            .tint(Color.themePrimary)
        }
        .modifier(PrivateFileExportModifier(file: $download, download: actions.download))
        .task(id: loadAttempt) { await model.load(using: actions.load) }
        .refreshable { await model.load(using: actions.load) }
    }

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
            showsUpload = true
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
    }

    private func insuranceRow(_ document: PatientDocument) -> some View {
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
            .padding(14)
            .background(Color.themeSurface, in: .rect(cornerRadius: 17))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(download != nil || document.download == nil)
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
        .disabled(download != nil || document.download == nil)
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
