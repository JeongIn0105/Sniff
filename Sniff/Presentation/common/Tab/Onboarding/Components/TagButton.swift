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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.black : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .foregroundColor(
                    isDisabled && !isSelected
                    ? Color.gray.opacity(0.4)
                    : Color.black
                )
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}
