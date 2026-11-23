//
//  DoctorWeeklyScheduleView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorWeeklyScheduleView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Schedule")
                .font(.title3.bold())
                .foregroundStyle(Color.themeText)

            VStack(spacing: 0) {
                row("Monday – Friday", hours: "08:00 AM – 04:00 PM")
                Divider()
                row("Saturday", hours: "09:00 AM – 01:00 PM")
                Divider()
                row("Sunday", hours: "Closed", isClosed: true)
            }
            .background(Color.themeSurface, in: .rect(cornerRadius: 16))

            Label {
                Text("Schedule is for reference only. No active booking slots available.")
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

    private func row(_ day: LocalizedStringKey, hours: LocalizedStringKey, isClosed: Bool = false) -> some View {
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
