//
//  DoctorAvatarView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct DoctorAvatarView: View {
    let doctor: Doctor
    var size: CGFloat = 80
    var showsAvailability = true

    var body: some View {
        VStack(spacing: -14) {
            Image(doctor.portraitName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .grayscale(doctor.isAvailable ? 0 : 1)
                .background(Color.themeSubtleSurface)
                .clipShape(.rect(cornerRadius: 23))

            if showsAvailability && doctor.isAvailable {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.themeAvailableDot)
                        .frame(width: 6, height: 6)

                    Text("Available")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.themeAvailableText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.themeAvailableBackground, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(Color.themeAvailableDot.opacity(0.25), lineWidth: 1)
                }
                .padding(2)
                .background(Color.themeSurface, in: Capsule())
            }
        }
    }
}

#Preview {
    HStack(alignment: .top, spacing: 16) {
        ForEach(Doctor.samples.prefix(2)) { doctor in
            DoctorAvatarView(doctor: doctor)
        }
    }
    .padding()
    .background(Color.themeCanvas)
}
