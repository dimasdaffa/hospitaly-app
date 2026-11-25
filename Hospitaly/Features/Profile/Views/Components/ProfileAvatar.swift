//
//  ProfileAvatar.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import CoreGraphics
import SwiftUI

struct ProfileAvatar: View {
    let url: URL?
    var photo: CGImage?
    var size: CGFloat = 94

    var body: some View {
        portrait
            .frame(width: size, height: size)
            .background(Color.themePrimary.opacity(0.08), in: .circle)
            .clipShape(Circle())
            .overlay { Circle().strokeBorder(Color.themeSurface, lineWidth: 3) }
    }

    @ContentBuilder
    private var portrait: some View {
        if let photo {
            Image(decorative: photo, scale: 1)
                .resizable()
                .scaledToFill()
        } else {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.39))
                        .foregroundStyle(Color.themePrimary)
                }
            }
        }
    }
}

#Preview {
    ProfileAvatar(url: nil)
}
