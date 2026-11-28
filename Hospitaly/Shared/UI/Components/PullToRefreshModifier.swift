//
//  PullToRefreshModifier.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 28/11/26.
//

import SwiftUI

private struct PullToRefreshModifier: ViewModifier {
    @State private var isRefreshing = false

    let isEnabled: Bool
    let action: @MainActor () async -> Void

    func body(content: Content) -> some View {
        content
            .scrollBounceBehavior(.always, axes: .vertical)
            .onScrollPhaseChange { oldPhase, newPhase, context in
                guard isEnabled, !isRefreshing, oldPhase == .interacting,
                      newPhase == .idle || newPhase == .decelerating else { return }

                let geometry = context.geometry
                let pullDistance = -(geometry.contentOffset.y + geometry.contentInsets.top)
                if pullDistance >= 56 {
                    isRefreshing = true
                }
            }
            .task(id: isRefreshing) {
                guard isRefreshing else { return }
                defer { isRefreshing = false }
                guard !Task.isCancelled else { return }
                await action()
            }
    }
}

extension View {
    func pullToRefresh(isEnabled: Bool = true, action: @escaping @MainActor () async -> Void) -> some View {
        modifier(PullToRefreshModifier(isEnabled: isEnabled, action: action))
    }
}

#Preview("Pull to Refresh") {
    @Previewable @State var isLoading = false

    ScrollView {
        if isLoading {
            LoadingStateView("Refreshing…")
                .frame(maxWidth: .infinity)
                .padding()
        } else {
            Text("Pull down to refresh")
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
    .pullToRefresh {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(for: .seconds(1))
    }
    .background(Theme.roseCanvas)
}
