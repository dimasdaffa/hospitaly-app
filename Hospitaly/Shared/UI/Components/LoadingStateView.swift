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

    let title: LocalizedStringKey
    var showsLightBackdrop: Bool

    private static let animation = LottieAnimation.named("loading", bundle: .main)
        ?? LottieAnimation.named("loading", bundle: .main, subdirectory: "Resources/Animations")

    init(_ title: LocalizedStringKey, showsLightBackdrop: Bool = false) {
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
                        .frame(width: 60, height: 44)
                        .background(showsLightBackdrop ? Color.themeSurface : .clear, in: Capsule())
                } else {
                    ProgressView()
                        .frame(width: 60, height: 44)
                }
            }
            .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LoadingStateView("Loading appointments…")
        .padding()
        .background(Theme.roseCanvas)
}
