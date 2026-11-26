//
//  MedicalRecordCard.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct MedicalRecordCard: View {
    let entry: MedicalRecordEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(entry.kind.rawValue.uppercased(), systemImage: entry.kind.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(accent.opacity(0.09), in: .rect(cornerRadius: 6))

                Spacer()

                if let date = entry.date {
                    Text(ClinicDate.label(date, as: .dateTime.day().month(.abbreviated)))
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.themeSubtleSurface, in: .rect(cornerRadius: 6))
                }
            }

            Text(entry.title)
                .font(.headline)
                .foregroundStyle(Color.themeText)

            if let provider = entry.provider {
                Text(provider)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.themeText)
            }

            if let summary = entry.summary, !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
                    .lineLimit(2)
            }

            Label("View Details", systemImage: "chevron.right")
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.themePrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hospitalyPanel()
    }

    private var accent: Color {
        switch entry.kind {
        case .diagnosis: .themePrimary
        case .lab: .themeExperienceAccent
        case .vaccination: .themeAvailableText
        }
    }
}

#Preview {
    MedicalRecordCard(entry: .lab(.sample))
        .padding()
        .background(Theme.roseCanvas)
}
