//
//  VitalMetricTabs.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct VitalMetricTabs: View {
    @Binding var selection: HealthMetric

    var body: some View {
        Picker("Vital Metric", selection: $selection) {
            ForEach(HealthMetric.allCases) { metric in
                Text(metric.title).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    @Previewable @State var metric = HealthMetric.bloodPressure
    VitalMetricTabs(selection: $metric)
        .padding()
}
