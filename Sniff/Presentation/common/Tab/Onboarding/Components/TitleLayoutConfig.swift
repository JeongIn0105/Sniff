//
//  TitleLayoutConfig.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import SwiftUI

struct TitleLayoutConfig: Codable {
    let fontSize: CGFloat
    let fontWeight: String
    let topOffsetRatio: CGFloat
    let leadingInset: CGFloat
    let lineSpacing: CGFloat

    static let `default` = TitleLayoutConfig(
        fontSize: 26,
        fontWeight: "bold",
        topOffsetRatio: 0.05,
        leadingInset: 24,
        lineSpacing: 4
    )

    var resolvedFontWeight: Font.Weight {
        fontWeight == "bold" ? .bold : .semibold
    }
}
