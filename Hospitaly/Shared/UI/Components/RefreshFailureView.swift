//
//  RefreshFailureView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 28/11/26.
//

import SwiftUI

struct RefreshFailureView: View {
    let message: String
    var isRetrying = false
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("Couldn’t refresh", systemImage: "exclamationmark.circle")
                .fontWeight(.semibold)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
            Button(isRetrying ? "Retrying…" : "Retry", action: onRetry)
                .fontWeight(.semibold)
                .buttonStyle(.plain)
                .frame(minHeight: 32)
                .disabled(isRetrying)
        }
        .font(.footnote)
        .foregroundStyle(Color.themeCrimsonInk)
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.themeGlassRose, in: .rect(cornerRadius: 14))
    }
}

#Preview {
    RefreshFailureView(message: "Check your internet connection and try again.", onRetry: {})
        .padding()
}
