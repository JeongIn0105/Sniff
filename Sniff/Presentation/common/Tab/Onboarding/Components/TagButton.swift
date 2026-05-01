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
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.sniffBeige : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.black : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1.5
                            )
                    )

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundColor(
                        isDisabled && !isSelected
                        ? Color.gray.opacity(0.4)
                        : Color.black
                    )

                if let selectionOrder {
                    Text("\(selectionOrder)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.black)
                        .clipShape(Circle())
                        .padding(10)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}
