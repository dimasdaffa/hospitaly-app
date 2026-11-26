//
//  ConversationRow.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 24/11/26.
//

import SwiftUI

struct ConversationRow: View {
    let conversation: Conversation
    let patientID: UUID

    var body: some View {
        HStack(spacing: 12) {
            MessageAvatar(peer: conversation.peer)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(conversation.name)
                        .font(.headline)
                        .foregroundStyle(Color.themeText)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if let date = conversation.latestMessage.createdAt {
                        Text(timestamp(date))
                            .font(.caption)
                            .foregroundStyle(conversation.unreadCount > 0 ? Color.themePrimary : .themeSecondaryText)
                    }
                }

                if let specialty = conversation.specialty, !specialty.isEmpty {
                    Text(specialty)
                        .font(.caption)
                        .foregroundStyle(Color.themeSecondaryText)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(previewText)
                        .font(.subheadline.weight(conversation.unreadCount > 0 ? .medium : .regular))
                        .foregroundStyle(Color.themeSecondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if conversation.unreadCount > 0 {
                        Text(conversation.unreadCount > 99 ? "99+" : String(conversation.unreadCount))
                            .font(.caption2.bold())
                            .monospacedDigit()
                            .foregroundStyle(Color.themeSurface)
                            .padding(.horizontal, 6)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Color.themePrimary, in: Capsule())
                    }
                }
            }
        }
        .padding(14)
        .hospitalyPanel(cornerRadius: 20)
        .contentShape(.rect(cornerRadius: 20))
    }

    private var previewText: String {
        let message = conversation.latestMessage
        return message.senderId == patientID ? "You: \(message.content)" : message.content
    }

    private func timestamp(_ date: Date) -> String {
        let calendar = ClinicDate.calendar
        if calendar.isDateInToday(date) { return ClinicDate.time(date) }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return ClinicDate.label(date, as: .dateTime.month(.abbreviated).day())
    }
}

#Preview {
    ConversationRow(conversation: .sample, patientID: MessagePeer.samplePatientID)
        .padding()
}
