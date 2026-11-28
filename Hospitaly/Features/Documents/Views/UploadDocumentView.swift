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
                HStack(spacing: 14) {
                    Group {
                        if model.isPicking {
                            ProgressView().tint(.themeSurface)
                        } else {
                            Image(systemName: model.file == nil ? "doc.badge.plus" : "checkmark")
                                .font(.title3.weight(.semibold))
                        }
                    }
                    .frame(width: 48, height: 48)
                    .background(Color.themeSurface.opacity(0.17), in: .rect(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 5) {
                        Group {
                            if let file = model.file {
                                Text(file.name).lineLimit(2)
                            } else {
                                Text(filePickerTitle)
                            }
                        }
                        .font(.title3.bold())

                        Text(filePickerDetail)
                            .font(.footnote)
                            .foregroundStyle(Color.themeSurface.opacity(0.87))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(Color.themeSurface)
                .padding(18)
                .background {
                    CrimsonHeaderBackdrop().clipShape(.rect(cornerRadius: Theme.cardRadius))
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
        return model.original == nil ? "Choose a File" : "Choose Replacement File"
    }

    private var filePickerDetail: String {
        if let file = model.file {
            return "\(file.data.count.formatted(.byteCount(style: .file))) · Tap to change"
        }
        if let original = model.original {
            return "Current file · \(original.size.formatted(.byteCount(style: .file)))\nPDF, JPEG, or PNG · up to 5 MiB"
        }
        return "PDF, JPEG, or PNG · up to 5 MiB"
    }

    private var metadataFields: some View {
        @Bindable var model = model

        return VStack(alignment: .leading, spacing: 15) {
            Text("Document Details")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)

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
        .padding(16)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func field(_ title: String, placeholder: String, icon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.themeText)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(Color.themeCrimsonInk)
                    .frame(width: 19)

                TextField(placeholder, text: text)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeText)
            }
            .padding(13)
            .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Color.themeGlassRose) }
        }
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Category")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                ForEach(DocumentCategory.uploadCategories) { category in
                    categoryButton(category)
                }
            }
        }
    }

    private func categoryButton(_ category: DocumentCategory) -> some View {
        let selected = category == model.category

        return Button {
            model.category = category
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    DocumentCategoryIcon(category: category, size: 32)
                    Spacer(minLength: 6)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? Color.themeCrimsonInk : Color.themeMutedText)
                }

                Text(category.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(selected ? Color.themeCrimsonInk : Color.themeText)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(selected ? Color.themeGlassRose : Color.themeSurface, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(selected ? Color.themeCrimsonInk : .themeCardBorder, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
