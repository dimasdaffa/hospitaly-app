//
//  VitalMetricTabs.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct VitalMetricTabs: View {
    @Binding var selection: HealthMetric
    var metrics = HealthMetric.allCases

    var body: some View {
        HStack(spacing: 4) {
            ForEach(metrics) { metric in
                Button {
                    selection = metric
                } label: {
                    Text(metric.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(selection == metric ? Color.themeSurface : Color.themeSecondaryText)
                        .frame(maxWidth: .infinity, minHeight: 39)
                        .background {
                            if selection == metric {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.themeCrimsonInk)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .hospitalyGlassSurface(in: Capsule())
    }
}

#Preview {
    @Previewable @State var metric = HealthMetric.bloodPressure
    VitalMetricTabs(selection: $metric)
        .padding()
}
