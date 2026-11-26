//
//  UploadDocumentView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct UploadDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: UploadDocumentViewModel
    @State private var showsFileImporter = false
    @State private var reconciledIDs: Set<UUID>?

    let actions: DocumentsActions
    let knownIDs: Set<UUID>
    let onRefresh: ([PatientDocument]) -> Void
    let onSaved: (PatientDocument) -> Void

    init(
        actions: DocumentsActions, knownIDs: Set<UUID>, original: PatientDocument? = nil,
        onRefresh: @escaping ([PatientDocument]) -> Void, onSaved: @escaping (PatientDocument) -> Void
    ) {
        _model = State(initialValue: UploadDocumentViewModel(original: original))
        self.actions = actions
        self.knownIDs = knownIDs
        self.onRefresh = onRefresh
        self.onSaved = onSaved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                filePicker
                metadataFields
                categories
            }
            .disabled(model.inputDisabled)
            .frame(maxWidth: 540)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle(model.original == nil ? "Upload Document" : "Edit Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(model.isSubmitting)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { submitBar }
        .interactiveDismissDisabled(model.isSubmitting)
        .fileImporter(isPresented: $showsFileImporter, allowedContentTypes: UploadDocumentFile.allowedTypes) { result in
            Task { await model.selectFile(result) }
        }
    }

    private var filePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showsFileImporter = true
            } label: {
                VStack(spacing: 8) {
                    if model.isPicking {
                        ProgressView()
                            .frame(height: 44)
                    } else {
                        Image(systemName: model.file == nil ? "icloud.and.arrow.up.fill" : "checkmark.circle.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.themePrimary)
                            .frame(width: 48, height: 48)
                            .background(Color.themePrimary.opacity(0.08), in: Circle())
                    }

                    if let file = model.file {
                        Text(file.name)
                            .font(.headline)
                            .foregroundStyle(Color.themeText)
                            .lineLimit(2)
                        Text("\(file.data.count.formatted(.byteCount(style: .file))) · Tap to change")
                            .font(.caption)
                            .foregroundStyle(Color.themeSecondaryText)
                    } else {
                        Text(filePickerTitle)
                            .font(.headline)
                            .foregroundStyle(Color.themeText)
                        Text(filePickerDetail)
                            .font(.caption)
                            .foregroundStyle(Color.themeSecondaryText)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 154)
                .padding(12)
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.themePrimary, style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if let error = model.fileError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.themePrimary)
            }

            if model.original != nil, model.file != nil || model.fileError != nil {
                Button("Keep Current File", action: model.keepCurrentFile)
                    .font(.footnote.weight(.semibold))
            }
        }
    }

    private var filePickerTitle: LocalizedStringKey {
        if model.isPicking { return "Opening File…" }
        return model.original == nil ? "Tap to Upload" : "Choose Replacement File"
    }

    private var filePickerDetail: String {
        if let original = model.original {
            return "Current file · \(original.size.formatted(.byteCount(style: .file)))\nPDF, JPEG, or PNG · up to 5 MiB"
        }
        return "PDF, JPEG, or PNG · up to 5 MiB"
    }

    private var metadataFields: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: 15) {
            field("Document Name", placeholder: "e.g. Health Insurance Policy", icon: "doc.text", text: $model.name)
            field(
                "Card Number / ID Number", placeholder: "Optional", icon: "creditcard",
                text: $model.cardNumber
            )
            .autocorrectionDisabled()

            if let error = model.metadataError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.themePrimary)
            }
        }
    }

    private func field(_ title: String, placeholder: String, icon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeText)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(Color.themeMutedText)
                    .frame(width: 19)

                TextField(placeholder, text: text)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeText)
            }
            .padding(13)
            .background(Color.themeSurface, in: .rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.themeOutline) }
        }
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Document Category")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeText)

            ForEach(DocumentCategory.uploadCategories) { category in
                categoryButton(category)
            }
        }
    }

    private func categoryButton(_ category: DocumentCategory) -> some View {
        let selected = category == model.category

        return Button {
            model.category = category
        } label: {
            HStack(spacing: 12) {
                DocumentCategoryIcon(category: category, size: 36)
                Text(category.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeText)
                Spacer(minLength: 8)
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Color.themePrimary : .themeOutline)
            }
            .padding(11)
            .background(selected ? Color.themeGlassRose : Color.themeSurface, in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(selected ? Color.themePrimary : .themeOutline, lineWidth: selected ? 1.5 : 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var submitBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = model.submissionError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Color.themePrimary)
            }

            if model.needsCheck {
                PrimaryActionButton(title: model.isSubmitting ? "Checking…" : "Check Documents", icon: "arrow.clockwise") {
                    Task { await checkUpload() }
                }
                .disabled(model.isBusy)
            } else {
                PrimaryActionButton(title: submitTitle) {
                    Task { await upload() }
                }
                .disabled(!model.canSubmit)
            }
        }
        .frame(maxWidth: 540)
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .hospitalyActionBar()
        .overlay(alignment: .top) { Divider() }
    }

    private var submitTitle: LocalizedStringKey {
        if model.original != nil {
            return model.isSubmitting ? "Saving…" : "Save Changes"
        }
        return model.isSubmitting ? "Uploading…" : "Submit Document"
    }

    private func upload() async {
        guard let document = await model.submit(knownIDs: reconciledIDs ?? knownIDs, using: actions) else {
            return
        }
        onSaved(document)
        dismiss()
    }

    private func checkUpload() async {
        guard let result = await model.check(using: actions) else { return }
        onRefresh(result.documents)
        reconciledIDs = Set(result.documents.map(\.id))
        if result.saved != nil { dismiss() }
    }
}

#Preview("Upload Document") {
    NavigationStack {
        UploadDocumentView(actions: .preview, knownIDs: [], onRefresh: { _ in }, onSaved: { _ in })
    }
}

#Preview("Edit Document") {
    NavigationStack {
        UploadDocumentView(
            actions: .preview, knownIDs: [PatientDocument.sampleCard.id], original: .sampleCard,
            onRefresh: { _ in }, onSaved: { _ in }
        )
    }
}
