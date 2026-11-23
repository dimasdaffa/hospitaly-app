//
//  PrimaryActionButton.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct PrimaryActionButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: LocalizedStringKey
    var icon: String?
    var cornerRadius: CGFloat = 16
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Text(title)
                    .font(.headline)

                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(isEnabled ? Color.themeSurface : Color.themeMutedText)
            .background {
                if isEnabled {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [.themePrimary, .themePrimaryHighlight],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.themePrimary.opacity(0.22), radius: 6, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.themeSubtleSurface)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryActionButton(title: "Continue to Reason", icon: "arrow.right") {}
        PrimaryActionButton(title: "Confirm Appointment") {}
            .disabled(true)
    }
    .padding()
}
