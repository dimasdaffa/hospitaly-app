//
//  QuickAccessSheet.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct QuickAccessSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onOpenTab: @MainActor (MainTab) -> Void
    let onOpenAppointments: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    shortcut(
                        "Appointments", subtitle: "Check schedule", icon: "calendar.badge.clock",
                        accent: .themeExperienceAccent, background: .themeExperienceBackground,
                        action: onOpenAppointments
                    )

                    shortcut(
                        "Find Doctors", subtitle: "Specialists list", icon: "stethoscope",
                        accent: .themePrimary, background: Color.themePrimary.opacity(0.08)
                    ) { onOpenTab(.doctors) }

                    shortcut(
                        "Health Tracker", subtitle: "Coming soon", icon: "waveform.path.ecg",
                        accent: .themeAvailableText, background: .themeAvailableBackground
                    )

                    shortcut(
                        "Messages", subtitle: "Coming soon", icon: "text.bubble",
                        accent: .themePurpleAccent, background: .themePurpleBackground
                    ) { onOpenTab(.chat) }

                    shortcut(
                        "Records", subtitle: "Coming soon", icon: "folder",
                        accent: .themeRecordsAccent, background: .themeRecordsBackground
                    )

                    shortcut(
                        "Profile", subtitle: "Account settings", icon: "person",
                        accent: .themeSecondaryText, background: .themeSubtleSurface
                    ) { onOpenTab(.profile) }
                }
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            quickBookButton
        }
        .background(Color.themeCanvas.ignoresSafeArea())
        .presentationBackground(Color.themeCanvas)
        .presentationDetents([.fraction(0.78), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Menu")
                    .font(.title.bold())
                    .foregroundStyle(Color.themeText)

                Text("Quick access to healthcare services")
                    .font(.subheadline)
                    .foregroundStyle(Color.themeSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismiss()
            } label: {
                Label("Close Menu", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeSecondaryText)
                    .frame(width: 36, height: 36)
                    .background(Color.themeSubtleSurface, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var quickBookButton: some View {
        Button {
            onOpenTab(.doctors)
        } label: {
            Label("QUICK BOOK", systemImage: "plus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.themeText)
                .padding(.horizontal, 22)
                .frame(minHeight: 50)
                .background(Color.themeQuickBook, in: Capsule())
                .shadow(color: Color.themeQuickBook.opacity(0.30), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 500, alignment: .trailing)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.themeCanvas, ignoresSafeAreaEdges: .bottom)
    }

    private func shortcut(
        _ title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String,
        accent: Color, background: Color, action: (@MainActor () -> Void)? = nil
    ) -> some View {
        Button(action: action ?? {}) {
            VStack(alignment: .leading, spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 48, height: 48)
                    .background(background, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Color.themeMutedText)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(Color.themeSurface, in: .rect(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.themeOutline.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: Color.themeCardShadow.opacity(0.35), radius: 2, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .opacity(action == nil ? 0.70 : 1)
    }
}

#Preview {
    @Previewable @State var isPresented = true

    Color.themeCanvas
        .sheet(isPresented: $isPresented) {
            QuickAccessSheet(
                onOpenTab: { _ in isPresented = false },
                onOpenAppointments: { isPresented = false }
            )
        }
}
