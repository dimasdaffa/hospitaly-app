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
                .background(Color.themeSurface, in: .rect(cornerRadius: 16))

                Label {
                    Text("Weekly hours are for reference. No bookable slots are available in the next 14 days.")
                        .font(.footnote)
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.themeMutedText)
                }
                .foregroundStyle(Color.themeSecondaryText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeExperienceBackground, in: .rect(cornerRadius: 14))
            }
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
        .background(Color.themeDetailCanvas)
}

#Preview("No Practice Schedule") {
    DoctorWeeklyScheduleView(weeklyHours: [])
        .padding()
        .background(Color.themeDetailCanvas)
}
