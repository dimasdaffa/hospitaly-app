//
//  VitalLogRow.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct VitalLogRow: View {
    let metric: HealthMetric
    let reading: HealthReading
    var showsDate = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: metric.symbol)
                .font(.headline)
                .foregroundStyle(Color.themeCrimsonInk)
                .frame(width: 44, height: 44)
                .background(Color.themeGlassRose, in: .rect(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                if let value = reading.measurement(for: metric) {
                    Text(metric.format(primary: value.primary, secondary: value.secondary))
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(Color.themeText)
                }

                if let timestamp {
                    Text(timestamp)
                        .font(.subheadline)
                        .foregroundStyle(Color.themeSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .hospitalyPanel(cornerRadius: 18)
    }

    private var timestamp: String? {
        if showsDate { return reading.dateLabel }
        guard let recordedAt = reading.recordedAt else { return nil }
        return ClinicDate.dayString(recordedAt) == reading.date ? ClinicDate.time(recordedAt) : reading.dateLabel
    }
}

#Preview {
    if let reading = HealthReading.samples.first {
        VitalLogRow(metric: .weight, reading: reading)
            .padding()
            .background(Theme.roseCanvas)
    }
}
