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
            portrait
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

    @ViewBuilder
    private var portrait: some View {
        if let name = doctor.portraitName {
            Image(name)
                .resizable()
                .scaledToFill()
        } else if let url = doctor.avatarURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Image(systemName: "person.crop.circle")
            .font(.system(size: size * 0.45, weight: .medium))
            .foregroundStyle(Color.themeMutedText)
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

#Preview("Missing Portrait") {
    let doctor = {
        var doctor = Doctor.samples[0]
        doctor.portraitName = nil
        return doctor
    }()

    DoctorAvatarView(doctor: doctor)
        .padding()
}
