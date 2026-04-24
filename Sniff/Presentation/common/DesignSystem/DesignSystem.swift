//
//   DesignSystem.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import Combine

extension Color {
    static let sniffBeige = Color(hex: "#F1E8DF")
    static let scentFloral  = Color(hex: "#e8a4b8")
    static let scentFresh   = Color(hex: "#7ecbb8")
    static let scentWoody   = Color(hex: "#a07850")
    static let scentAmber   = Color(hex: "#c8782a")
    static let scentAquatic = Color(hex: "#4a90b8")
    static let scentSpicy   = Color(hex: "#9a3a4a")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Font {
    static let sniffTitle = Font.system(size: 24, weight: .bold)
    static let sniffBody  = Font.system(size: 16, weight: .regular)
    static let sniffCaption = Font.system(size: 12, weight: .regular)
}
