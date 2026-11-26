//
//  HomeHeaderBackdrop.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 27/11/26.
//

import SwiftUI

struct HomeHeaderBackdrop: View {
    var body: some View {
        Theme.crimsonGradient
            .overlay {
                RadialGradient(
                    colors: [.themePrimary.opacity(0.50), .clear],
                    center: .topTrailing, startRadius: 16, endRadius: 310
                )
            }
            .overlay {
                Canvas { context, size in
                    let width = size.width
                    let height = size.height

                    var upper = Path()
                    upper.move(to: CGPoint(x: -0.08 * width, y: 0.34 * height))
                    upper.addCurve(
                        to: CGPoint(x: 1.10 * width, y: 0.03 * height),
                        control1: CGPoint(x: 0.38 * width, y: 0.50 * height),
                        control2: CGPoint(x: 0.31 * width, y: -0.26 * height)
                    )
                    context.stroke(upper, with: .color(.themeSurface.opacity(0.19)), lineWidth: 1.25)

                    var lower = Path()
                    lower.move(to: CGPoint(x: -0.20 * width, y: 0.86 * height))
                    lower.addCurve(
                        to: CGPoint(x: 1.16 * width, y: 0.36 * height),
                        control1: CGPoint(x: 0.51 * width, y: 1.30 * height),
                        control2: CGPoint(x: 0.75 * width, y: 0.02 * height)
                    )
                    context.stroke(lower, with: .color(.themeSurface.opacity(0.15)), lineWidth: 1.5)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    HomeHeaderBackdrop()
        .frame(height: 320)
}
