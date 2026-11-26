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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: metric.symbol)
                .foregroundStyle(Color.themePrimary)
                .frame(width: 42, height: 42)
                .background(Color.themePrimary.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                if let value = reading.measurement(for: metric) {
                    Text(metric.format(primary: value.primary, secondary: value.secondary))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.themeText)
                }

                Text(reading.dateLabel)
                    .font(.caption)
                    .foregroundStyle(Color.themeSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .hospitalyPanel(cornerRadius: 18)
    }
}

#Preview {
    if let reading = HealthReading.samples.first {
        VitalLogRow(metric: .weight, reading: reading)
            .padding()
            .background(Theme.roseCanvas)
    }
}
