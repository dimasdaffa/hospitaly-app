//
//  DoctorWeeklyScheduleView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import SwiftUI

struct DoctorWeeklyScheduleView: View {
    var weeklyHours: [DoctorDetailData.WeeklyHours]? = nil
    var hasBookableSlots = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Schedule")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)

            if let weeklyHours, weeklyHours.isEmpty {
                ContentUnavailableView(
                    "No Practice Schedule", systemImage: "calendar",
                    description: Text("This doctor hasn’t added weekly practice hours yet.")
                )
            } else {
                VStack(spacing: 0) {
                    if let weeklyHours {
                        ForEach(weeklyHours) { entry in
                            row(
                                entry.dayOfWeek.capitalized,
                                hours: entry.isAvailable ? "\(entry.startTime) – \(entry.endTime) WIB" : "Unavailable",
                                isClosed: !entry.isAvailable
                            )
                            if entry.id != weeklyHours.last?.id {
                                Divider()
                            }
                        }
                    } else {
                        row("Monday – Friday", hours: "08:00 AM – 04:00 PM")
                        Divider()
                        row("Saturday", hours: "09:00 AM – 01:00 PM")
                        Divider()
                        row("Sunday", hours: "Closed", isClosed: true)
                    }
                }
                .hospitalyGlassSurface(in: RoundedRectangle(cornerRadius: 18))
            }

            Label {
                if hasBookableSlots {
                    Text("Weekly hours are for reference. Open Appointment to select an available time.")
                } else {
                    Text("No bookable slots are available in the next 14 days.")
                }
            } icon: {
                Image(systemName: "info.circle")
            }
            .font(.footnote)
            .foregroundStyle(Color.themeCrimsonInk)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.themeGlassRose, in: .rect(cornerRadius: 14))
        }
    }

    private func row(_ day: String, hours: String, isClosed: Bool = false) -> some View {
        HStack {
            Text(day)
                .foregroundStyle(Color.themeSecondaryText)

            Spacer(minLength: 8)

            Text(hours)
                .fontWeight(.semibold)
                .foregroundStyle(isClosed ? Color.themeMutedText : Color.themeText)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 17)
    }
}

#Preview {
    DoctorWeeklyScheduleView()
        .padding()
        .background(Theme.dashboardCanvas)
}

#Preview("No Practice Schedule") {
    DoctorWeeklyScheduleView(weeklyHours: [])
        .padding()
        .background(Theme.dashboardCanvas)
}
