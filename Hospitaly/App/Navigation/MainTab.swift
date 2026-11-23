//
//  MainTab.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

enum MainTab: Hashable {
    case home
    case doctors
    case chat
    case profile

    var title: LocalizedStringKey {
        switch self {
        case .home: "Home"
        case .doctors: "Doctors"
        case .chat: "Chat"
        case .profile: "Profile"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .doctors: "stethoscope"
        case .chat: "bubble.left"
        case .profile: "person"
        }
    }
}
