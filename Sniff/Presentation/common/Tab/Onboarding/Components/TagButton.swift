//
//  TagButton.swift
//  Sniff
//
//  Created by Codex on 2026.04.15.
//

import SwiftUI

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let isDisabled: Bool
    let selectionOrder: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        isDisabled && !isSelected
                        ? Color(hex: "#B8BEC8")
                        : Color(hex: "#1F2937")
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color(hex: "#F7EEE5") : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? Color.black : Color(hex: "#E4E7EC"),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.black.opacity(0.10) : Color.black.opacity(0.045),
                radius: isSelected ? 12 : 8,
                x: 0,
                y: isSelected ? 7 : 4
            )
            .opacity(isDisabled && !isSelected ? 0.55 : 1)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}
