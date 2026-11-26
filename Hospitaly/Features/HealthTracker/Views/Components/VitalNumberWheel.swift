//
//  VitalNumberWheel.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import SwiftUI

struct VitalNumberWheel: View {
    let title: String
    let unit: String
    let values: ClosedRange<Int>
    @Binding var selection: Int?
    var decimalPlaces = 0
    var digitSize: CGFloat = 40

    private let wheelHeight: CGFloat = 186
    private let rowHeight: CGFloat = 51

    var body: some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Color.themeMutedText)

            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(values, id: \.self) { value in
                        numberRow(value)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .contentMargins(.vertical, (wheelHeight - rowHeight) / 2, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned(anchor: .center))
            .scrollPosition(id: $selection, anchor: .center)
            .frame(height: wheelHeight)
            .mask {
                LinearGradient(
                    stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.32),
                            .init(color: .black, location: 0.68), .init(color: .clear, location: 1)],
                    startPoint: .top, endPoint: .bottom
                )
            }
            .background {
                RoundedRectangle(cornerRadius: 27)
                    .fill(Color.themeGlassRose.opacity(0.7))
                    .overlay { selectionHighlight }
            }
            .sensoryFeedback(.selection, trigger: selection)
        }
        .frame(maxWidth: .infinity)
    }

    private var selectionHighlight: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.themeSurface)
            .strokeBorder(Color.themePrimary.opacity(0.23), lineWidth: 1)
            .frame(height: rowHeight)
            .padding(.horizontal, 8)
    }

    private func numberRow(_ value: Int) -> some View {
        let selected = selection == value
        let number = decimalPlaces == 1 ? Double(value) / 10 : Double(value)
        let label = number.formatted(.number.grouping(.never).precision(.fractionLength(decimalPlaces)))

        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(label)
                .font(.system(size: selected ? digitSize : 25, weight: selected ? .bold : .medium))
                .monospacedDigit()
                .foregroundStyle(selected ? Color.themePrimary : Color.themeMutedText)

            if selected {
                Text(unit)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.themeMutedText)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.65)
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight)
        .padding(.horizontal, 10)
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.snappy) { selection = value }
        }
    }
}

#Preview {
    @Previewable @State var selection: Int? = 721
    VitalNumberWheel(title: "Weight", unit: "kg", values: 1...5_000, selection: $selection, decimalPlaces: 1)
        .padding()
}
