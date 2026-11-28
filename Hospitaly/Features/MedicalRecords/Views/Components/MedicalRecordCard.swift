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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.kind.symbol)
                .font(.headline)
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(accent.opacity(0.10), in: .rect(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.kind.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)

                    if let date = entry.date {
                        Spacer(minLength: 0)
                        Text(ClinicDate.label(date, as: .dateTime.day().month(.abbreviated)))
                            .font(.caption)
                            .foregroundStyle(Color.themeSecondaryText)
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.themeCrimsonInk)
                .padding(.top, 14)
        }
        .padding(16)
        .hospitalyPanel()
        .contentShape(.rect(cornerRadius: Theme.cardRadius))
    }

    private var accent: Color {
        switch entry.kind {
        case .diagnosis: .themeCrimsonInk
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
