//
//  MainTabBar.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct MainTabBar: View {
    @Binding var selection: MainTab
    var hasUnreadMessages = false
    let onQuickAccess: @MainActor () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            tabButton(.home)
            tabButton(.doctors)

            Button(action: onQuickAccess) {
                Label("Quick Access", systemImage: "square.grid.2x2")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.themeSurface)
                    .frame(width: 52, height: 52)
                    .background(Color.themePrimary, in: Circle())
                    .padding(4)
                    .background(Color.themeSurface, in: Circle())
                    .shadow(color: Color.themePrimary.opacity(0.30), radius: 8, y: 5)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            tabButton(.chat)
            tabButton(.profile)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
        .frame(maxWidth: 540)
        .frame(maxWidth: .infinity)
        .background {
            VStack(spacing: 0) {
                Color.themeDivider.frame(height: 1)
                Color.themeSurface
            }
            .padding(.top, 8)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func tabButton(_ tab: MainTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .overlay(alignment: .topTrailing) {
                        if tab == .chat && hasUnreadMessages {
                            Circle()
                                .fill(Color.themePrimaryHighlight)
                                .frame(width: 7, height: 7)
                                .offset(x: 5, y: -1)
                        }
                    }

                Text(tab.title)
                    .font(.caption2.weight(selection == tab ? .semibold : .medium))
            }
            .foregroundStyle(selection == tab ? Color.themePrimary : Color.themeMutedText)
            .frame(maxWidth: .infinity)
            .frame(height: 49)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
    }
}

#Preview {
    @Previewable @State var selection = MainTab.doctors

    Color.themeCanvas
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MainTabBar(selection: $selection, onQuickAccess: {})
        }
}
