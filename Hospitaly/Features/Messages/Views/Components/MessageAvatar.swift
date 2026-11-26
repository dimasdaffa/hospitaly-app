//
//  MessageAvatar.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct MessageAvatar: View {
    let peer: MessagePeer
    var size: CGFloat = 50

    var body: some View {
        AsyncImage(url: peer.avatarURL) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.39))
                    .foregroundStyle(Color.themeMutedText)
            }
        }
        .frame(width: size, height: size)
        .background(Color.themeGlassRose, in: Circle())
        .clipShape(Circle())
    }
}

#Preview {
    MessageAvatar(peer: .sample)
        .padding()
}
