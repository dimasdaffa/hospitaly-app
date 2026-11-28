//
//  LoadingStateView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 28/11/26.
//

import Foundation
import Lottie
import SwiftUI

struct LoadingStateView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: LocalizedStringKey?
    let showsLightBackdrop: Bool

    private static let animation = LottieAnimation.named("loading", bundle: .main)
        ?? LottieAnimation.named("loading", bundle: .main, subdirectory: "Animations")
        ?? LottieAnimation.named("loading", bundle: .main, subdirectory: "Resources/Animations")

    init(_ title: LocalizedStringKey? = nil, showsLightBackdrop: Bool = false) {
        self.title = title
        self.showsLightBackdrop = showsLightBackdrop
    }

    var body: some View {
        VStack(spacing: 2) {
            Group {
                if let animation = Self.animation, !reduceMotion {
                    LottieView(animation: animation)
                        .resizable()
                        .looping()
                } else {
                    Image(systemName: "hourglass")
                        .font(title == nil ? .caption.weight(.semibold) : .title3)
                        .foregroundStyle(Color.themeCrimsonInk)
                }
            }
            .frame(width: title == nil ? 24 : 60, height: title == nil ? 20 : 44)
            .background(showsLightBackdrop ? Color.themeSurface : .clear, in: Capsule())
            .accessibilityHidden(true)

            if let title {
                Text(title)
                    .font(.subheadline)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title ?? "In progress"))
    }
}

#Preview {
    VStack(spacing: 16) {
        LoadingStateView("Loading appointments…")
        LoadingStateView()
    }
    .padding()
    .background(Theme.roseCanvas)
}
