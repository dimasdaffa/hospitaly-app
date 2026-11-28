//
//  DiagnosisDetailView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct DiagnosisDetailView: View {
    @State private var record: MedicalRecord?
    @State private var error: String?
    @State private var loadAttempt = 0
    @State private var attachments: [RecordAttachment] = []
    @State private var attachmentPhase = MedicalRecordsViewModel.Phase.loading
    @State private var attachmentAttempt = 0
    @State private var download: PrivateDocumentDownload?

    let recordID: UUID
    let actions: MedicalRecordsActions
    let onFollowUp: (Doctor) -> Void
    var onChat: ((Doctor) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let record {
                    details(record)
                } else if let error {
                    ContentUnavailableView {
                        Label("Couldn’t Load Record", systemImage: "exclamationmark.circle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { loadAttempt += 1 }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    LoadingStateView("Loading record…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 38)
                }
            }
            .frame(maxWidth: 540)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle(record?.recordType == "vaccination" ? "Vaccination Details" : "Diagnosis Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let record, record.recordType != "vaccination", let clinician = record.appointment?.doctor {
                actionBar(actions.displayDoctor(clinician))
            }
        }
        .modifier(PrivateFileExportModifier(file: $download, download: actions.download))
        .task(id: loadAttempt) { await loadRecord() }
        .task(id: attachmentAttempt) { await loadAttachments() }
    }

    private func actionBar(_ doctor: Doctor) -> some View {
        HStack(spacing: 10) {
            if let onChat, doctor.userId != nil {
                Button {
                    onFollowUp(doctor)
                } label: {
                    Text("Book Follow-up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeText)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Color.themeSurface, in: .rect(cornerRadius: 16))
                        .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Color.themeOutline) }
                }
                .buttonStyle(.plain)

                PrimaryActionButton(title: "Chat Doctor", icon: "bubble.left") { onChat(doctor) }
            } else {
                PrimaryActionButton(title: "Book Follow-up", icon: "calendar") { onFollowUp(doctor) }
            }
        }
        .frame(maxWidth: 540)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .hospitalyActionBar()
    }

    @ContentBuilder
    private func details(_ record: MedicalRecord) -> some View {
        providerCard(record)
        diagnosisCard(record)

        if let medications = record.medications, !medications.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("Medicines & Care")
                ForEach(medications) { medication in medicationCard(medication) }
            }
        } else if let prescription = record.prescription, !prescription.isEmpty {
            textSection("Prescription", text: prescription)
        }

        if !record.treatment.isEmpty {
            textSection("Treatment", text: record.treatment)
        }

        if let notes = record.notes, !notes.isEmpty {
            textSection("Doctor’s Notes", text: notes)
        }

        if record.followUpRequired {
            let date = record.followUpDate.flatMap { ClinicDate.date(day: $0, time: "00:00") }
            let label = date.map { ClinicDate.label($0, as: .dateTime.day().month(.wide).year()) }
            textSection("Follow-up", text: label ?? "Follow-up requested by your care team.")
        }

        documentSection
    }

    private func providerCard(_ record: MedicalRecord) -> some View {
        let doctor = record.appointment?.doctor.map(actions.displayDoctor)
        return HStack(spacing: 13) {
            AsyncImage(url: doctor?.avatarURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.themeMutedText)
                }
            }
            .frame(width: 54, height: 54)
            .background(Color.themeSubtleSurface, in: Circle())
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(doctor?.name ?? "Care Provider Unavailable")
                    .font(.headline)
                    .foregroundStyle(Color.themeText)

                if let doctor {
                    Text(doctor.specialty)
                        .font(.subheadline)
                        .foregroundStyle(Color.themePrimary)
                }

                if let date = record.visitDate {
                    Label(ClinicDate.label(date, as: .dateTime.day().month(.abbreviated).year()), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func diagnosisCard(_ record: MedicalRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle(record.recordType == "vaccination" ? "Vaccination" : "The Diagnosis")
                Spacer()
                if let severity = record.severity, !severity.isEmpty {
                    Text(severity.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.themePendingText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.themePendingBackground, in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(record.diagnosis)
                    .font(.title2.bold())
                    .foregroundStyle(Color.themeCrimsonInk)

                if !record.symptoms.isEmpty {
                    Text(record.symptoms)
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                }

                if let tags = record.symptomTags, !tags.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(Array(Set(tags)).sorted(), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.themeSecondaryText)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(Color.themeGlassRose.opacity(0.75), in: Capsule())
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .hospitalyPanel(cornerRadius: 20)
        }
    }

    private func medicationCard(_ medication: MedicalRecord.Medication) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pills.fill")
                .foregroundStyle(Color.themeExperienceAccent)
                .frame(width: 38, height: 38)
                .background(Color.themeExperienceBackground, in: .rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(medication.name)
                    .font(.headline)
                    .foregroundStyle(Color.themeText)
                Text([medication.dose, medication.category].compactMap { $0 }.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)

                if !medication.times.isEmpty {
                    Label(medication.times.sorted().joined(separator: " · "), systemImage: "clock")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.themeSecondaryText)
                }
                if let instructions = medication.instructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(15)
        .hospitalyPanel(cornerRadius: 20)
    }

    private func textSection(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondaryText)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .hospitalyPanel(cornerRadius: 20)
        }
    }

    private var documentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Documents")

            switch attachmentPhase {
            case .loading:
                LoadingStateView("Loading attachments…")
                    .font(.subheadline)
            case .failed:
                HStack {
                    Text("Couldn’t load attachments.")
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                    Spacer()
                    Button("Retry") { attachmentAttempt += 1 }
                        .font(.subheadline.weight(.semibold))
                }
            case .loaded:
                if attachments.isEmpty {
                    Label("No documents attached to this record.", systemImage: "doc")
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                } else {
                    ForEach(attachments) { attachment in attachmentRow(attachment) }
                }
            }
        }
    }

    private func attachmentRow(_ attachment: RecordAttachment) -> some View {
        Button {
            download = attachment.file
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .foregroundStyle(Color.themeExperienceAccent)
                    .frame(width: 36, height: 36)
                    .background(Color.themeExperienceBackground, in: .rect(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeText)
                    Text(attachment.size.formatted(.byteCount(style: .file)))
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                }

                Spacer()

                if download?.source == .document(attachment.id) {
                    ProgressView()
                } else if attachment.file != nil {
                    Image(systemName: "arrow.down.to.line")
                        .foregroundStyle(Color.themePrimary)
                }
            }
            .padding(13)
            .hospitalyPanel(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .disabled(download != nil || attachment.file == nil)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.5)
            .foregroundStyle(Color.themeSecondaryText)
    }

    private func loadRecord() async {
        error = nil
        do {
            let result = try await actions.loadRecord(recordID)
            try Task.checkCancellation()
            record = result
        } catch where !Task.isCancelled && !(error is CancellationError) {
            self.error = error.localizedDescription
        } catch {
            return
        }
    }

    private func loadAttachments() async {
        attachmentPhase = .loading
        do {
            let result = try await actions.loadAttachments(recordID)
            try Task.checkCancellation()
            attachments = result
            attachmentPhase = .loaded
        } catch where !Task.isCancelled && !(error is CancellationError) {
            attachmentPhase = .failed(error.localizedDescription)
        } catch {
            return
        }
    }
}

#Preview("Diagnosis") {
    NavigationStack {
        DiagnosisDetailView(recordID: MedicalRecord.sample.id, actions: .preview, onFollowUp: { _ in }, onChat: { _ in })
    }
    .tint(Color.themePrimary)
}

#Preview("No Attachments") {
    NavigationStack {
        DiagnosisDetailView(recordID: MedicalRecord.sample.id, actions: .previewEmpty, onFollowUp: { _ in })
    }
    .tint(Color.themePrimary)
}
