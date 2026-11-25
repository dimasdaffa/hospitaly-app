//
//  DocumentCategoryIcon.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import SwiftUI

struct DocumentCategoryIcon: View {
    let category: DocumentCategory
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: category.icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(accent)
            .frame(width: size, height: size)
            .background(accent.opacity(0.10), in: .rect(cornerRadius: 11))
    }

    private var accent: Color {
        switch category {
        case .bpjs: .themeAvailableText
        case .insurance, .familyCard, .clinicalAttachment: .themeExperienceAccent
        case .idCard: .themeRecordsAccent
        case .other: .themeSecondaryText
        }
    }
}

#Preview {
    HStack {
        DocumentCategoryIcon(category: .bpjs)
        DocumentCategoryIcon(category: .idCard)
        DocumentCategoryIcon(category: .familyCard)
    }
    .padding()
}
