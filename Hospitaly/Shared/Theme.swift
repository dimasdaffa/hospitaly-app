//
//  Theme.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

enum Theme {
    enum GlassTone: Equatable {
        case light, crimson
    }

    static let contentInset: CGFloat = 20
    static let dashboardWidth: CGFloat = 560
    static let sectionSpacing: CGFloat = 28
    static let cardRadius: CGFloat = 24
    static let heroRadius: CGFloat = 34
    static let searchOverlap: CGFloat = 27

    static var crimsonGradient: LinearGradient {
        LinearGradient(
            colors: [.themeCrimsonDeep, .themeCrimsonShade],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    static var roseCanvas: LinearGradient {
        LinearGradient(
            colors: [.themeGlassRose, .themeGlassCanvas, .themeGlassCanvas],
            startPoint: .top, endPoint: .bottomTrailing
        )
    }
}

extension Color {
    static let themePrimary = Color(hex: 0xDB143C)
    static let themePrimaryHighlight = Color(hex: 0xF04143)
    static let themeCrimsonDeep = Color(hex: 0x510D2A)
    static let themeCrimsonShade = Color(hex: 0xB01B45)
    static let themeCrimsonInk = Color(hex: 0xA31138)
    static let themeGlassRose = Color(hex: 0xF6E2EB)
    static let themeGlassCanvas = Color(hex: 0xFFF8FB)
    static let themeVitalAccent = Color(hex: 0xED172C)
    static let themeCanvas = Color(hex: 0xF7F5F5)
    static let themeSurface = Color.white
    static let themeSubtleSurface = Color(hex: 0xF3F4F6)

    static let themeText = Color(hex: 0x131C2C)
    static let themeSecondaryText = Color(hex: 0x536074)
    static let themeMutedText = Color(hex: 0x93A2B7)

    static let themeOutline = Color(hex: 0xDCE4F1)
    static let themeDivider = Color(hex: 0xECEEF1)
    static let themeCardBorder = Color(hex: 0xEFEDF0)
    static let themeCardShadow = Color(hex: 0x0F172A, opacity: 0.12)

    static let themeAvailableText = Color(hex: 0x138344)
    static let themeAvailableDot = Color(hex: 0x19BE66)
    static let themeAvailableBackground = Color(hex: 0xDDFBE8)

    static let themePendingText = Color(hex: 0x9C6208)
    static let themePendingBackground = Color(hex: 0xFFF5CD)

    static let themeRatingAccent = Color(hex: 0xEEA800)
    static let themeRatingBackground = Color(hex: 0xFFF9E4)
    static let themeExperienceAccent = Color(hex: 0x4D8DFB)
    static let themeExperienceBackground = Color(hex: 0xEDF4FF)
    static let themePurpleAccent = Color(hex: 0xA55EF5)
    static let themePurpleBackground = Color(hex: 0xF7EFFF)

    static let themeRecordsAccent = Color(hex: 0xDA5210)
    static let themeRecordsBackground = Color(hex: 0xFFF3E6)
    static let themeQuickBook = Color(hex: 0xFFBD09)
}

extension View {
    func hospitalyGlassSurface<S: InsettableShape>(
        in shape: S, tone: Theme.GlassTone = .light
    ) -> some View {
        let onCrimson = tone == .crimson
        let tint = onCrimson ? Color.themeSurface.opacity(0.09) : Color.themeSurface.opacity(0.68)

        return background {
            shape
                .fill(.thinMaterial)
                .environment(\.colorScheme, onCrimson ? .dark : .light)
                .opacity(onCrimson ? 0.40 : 1)
                .overlay { shape.fill(tint) }
                .overlay {
                    shape.strokeBorder(
                        LinearGradient(
                            colors: [.themeSurface.opacity(0.94), .themeSurface.opacity(onCrimson ? 0.18 : 0.55)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: Color.themeCrimsonDeep.opacity(onCrimson ? 0.22 : 0.13), radius: 12, y: 5)
        }
    }

    func hospitalyPanel(cornerRadius: CGFloat = Theme.cardRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        return background {
            shape
                .fill(Color.themeSurface.opacity(0.90))
                .overlay { shape.strokeBorder(Color.themeSurface, lineWidth: 1) }
                .shadow(color: Color.themeCrimsonDeep.opacity(0.08), radius: 8, y: 3)
        }
    }

    func hospitalyActionBar() -> some View {
        background {
            Rectangle()
                .fill(.regularMaterial)
                .environment(\.colorScheme, .light)
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

// MARK: - Convenience Initializers
extension Color {
    
    /// Initialize a color using a hex integer value (e.g., `0xF2EFE7`)
    init(hex: UInt32, opacity: Double = 1.0) {
        let red   = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8)  / 255.0
        let blue  = Double(hex & 0x0000FF)         / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
