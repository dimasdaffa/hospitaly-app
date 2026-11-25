//
//  LabResultDetailView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct LabResultDetailView: View {
    @State private var result: LabResult?
    @State private var error: String?
    @State private var loadAttempt = 0
    @State private var download: PrivateDocumentDownload?

    let resultID: UUID
    let actions: MedicalRecordsActions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let result {
                    report(result)
                } else if let error {
                    ContentUnavailableView {
                        Label("Couldn’t Load Lab Result", systemImage: "exclamationmark.circle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") { loadAttempt += 1 }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ProgressView("Loading lab result…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 38)
                }
            }
            .frame(maxWidth: 540)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.themeCanvas.ignoresSafeArea())
        .navigationTitle("Lab Results")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let file = result?.pdf {
                PrimaryActionButton(
                    title: download == nil ? "Download PDF" : "Downloading…", icon: "arrow.down.to.line"
                ) { download = file }
                .disabled(download != nil)
                .frame(maxWidth: 540)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.themeSurface, ignoresSafeAreaEdges: .bottom)
            }
        }
        .modifier(PrivateFileExportModifier(file: $download, download: actions.download))
        .task(id: loadAttempt) { await load() }
    }

    @ContentBuilder
    private func report(_ result: LabResult) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(result.title)
                .font(.title2.bold())
                .foregroundStyle(Color.themeText)
            Label(result.laboratory, systemImage: "mappin")
            Label(
                ClinicDate.label(result.collectedAt, as: .dateTime.day().month(.abbreviated).year().hour().minute()),
                systemImage: "clock"
            )
        }
        .font(.subheadline)
        .foregroundStyle(Color.themeSecondaryText)

        if let alert = result.alert, !alert.isEmpty {
            callout("Attention Needed", detail: alert, icon: "exclamationmark.triangle.fill", accent: .themePrimary)
        }

        if result.panels.isEmpty {
            ContentUnavailableView(
                "No Measurements", systemImage: "testtube.2",
                description: Text("Published measurements will appear here.")
            )
        } else {
            ForEach(result.panels.indices, id: \.self) { index in
                panelCard(result.panels[index])
            }
        }

        if let note = result.doctorNote, !note.isEmpty {
            doctorNote(note, author: result.authorName, specialty: result.authorSpecialty)
        }

        if result.pdf == nil {
            Label("No PDF attached to this report.", systemImage: "doc")
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondaryText)
        }
    }

    private func panelCard(_ panel: LabResult.Panel) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text(panel.name)
                    .font(.headline)
                    .foregroundStyle(Color.themeText)
                if let status = panel.status, !status.isEmpty {
                    statusBadge(status)
                }
            }

            ForEach(panel.measurements.indices, id: \.self) { index in
                measurementRow(panel.measurements[index])
            }

            if let summary = panel.summary, !summary.isEmpty {
                callout("Summary", detail: summary, icon: "text.alignleft", accent: statusColor(panel.status))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeSurface, in: .rect(cornerRadius: 19))
        .overlay { RoundedRectangle(cornerRadius: 19).strokeBorder(Color.themeCardBorder) }
    }

    private func measurementRow(_ measurement: LabResult.Measurement) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(measurement.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.themeSecondaryText)
                Spacer(minLength: 5)
                Text(measurement.value)
                    .font(.headline)
                    .foregroundStyle(statusColor(measurement.status) == .themePrimary ? Color.themePrimary : .themeText)
                if let unit = measurement.unit, !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }

            if let range = measurement.referenceRange, !range.isEmpty {
                Text("Reference range \(range)")
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
            }
        }
        .padding(.vertical, 3)
    }

    private func doctorNote(_ note: String, author: String?, specialty: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Doctor’s Note")
                .font(.headline)
                .foregroundStyle(Color.themeText)

            VStack(alignment: .leading, spacing: 7) {
                if let author {
                    Label(author, systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.themeText)
                }

                if let specialty {
                    Text(specialty)
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                }

                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.themeSurface, in: .rect(cornerRadius: 16))
        }
    }

    private func statusBadge(_ status: String) -> some View {
        let accent = statusColor(status)
        return Text(status.capitalized)
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(accent.opacity(0.09), in: .rect(cornerRadius: 6))
    }

    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "normal": .themeAvailableText
        case "elevated", "high", "low", "critical", "abnormal": .themePrimary
        default: .themeSecondaryText
        }
    }

    private func callout(_ title: String, detail: String, icon: String, accent: Color) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: icon)
        }
        .foregroundStyle(accent)
        .padding(14)
        .background(accent.opacity(0.08), in: .rect(cornerRadius: 13))
    }

    private func load() async {
        error = nil
        do {
            let report = try await actions.loadLab(resultID)
            try Task.checkCancellation()
            result = report
        } catch where !Task.isCancelled && !(error is CancellationError) {
            self.error = error.localizedDescription
        } catch {
            return
        }
    }
}

#Preview("Lab Result") {
    NavigationStack {
        LabResultDetailView(resultID: LabResult.sample.id, actions: .preview)
    }
    .tint(Color.themePrimary)
}

#Preview("Empty Report") {
    NavigationStack {
        LabResultDetailView(resultID: LabResult.emptySample.id, actions: .previewEmpty)
    }
    .tint(Color.themePrimary)
}
