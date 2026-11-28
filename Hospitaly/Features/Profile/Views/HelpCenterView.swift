//
//  HelpCenterView.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct HelpCenterView: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                header

                ForEach(HelpTopic.faq, id: \.self) { topic in
                    topicCard(topic)
                }
            }
            .padding(Theme.contentInset)
            .frame(maxWidth: Theme.dashboardWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { Theme.roseCanvas.ignoresSafeArea() }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Label("Frequently Asked Questions", systemImage: "questionmark.bubble")
            .font(.title2.bold())
            .foregroundStyle(Color.themeSurface)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                CrimsonHeaderBackdrop().clipShape(.rect(cornerRadius: Theme.cardRadius))
            }
    }

    private func topicCard(_ topic: HelpTopic) -> some View {
        DisclosureGroup {
            Text(topic.answer)
                .font(.subheadline)
                .foregroundStyle(Color.themeSecondaryText)
                .lineSpacing(3)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeGlassCanvas, in: .rect(cornerRadius: 12))
                .padding(.top, 8)
        } label: {
            Text(topic.title)
                .font(.headline)
                .foregroundStyle(Color.themeText)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .tint(Color.themeCrimsonInk)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .hospitalyPanel(cornerRadius: 20)
    }
}

#Preview("Help Topics") {
    NavigationStack {
        HelpCenterView()
    }
}
