//
//  Theme.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

extension Color {
    static let themePrimary = Color(hex: 0xDB143C)
    static let themePrimaryHighlight = Color(hex: 0xF04143)
    static let themeDashboardHeroEnd = Color(hex: 0xFF859A)
    static let themeDetailCanvas = Color(hex: 0xF5F7F9)
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
