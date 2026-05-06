//
//  SniffLogoText.swift
//  Sniff
//
//  Created by Codex on 2026.05.05.
//

import SwiftUI

struct SniffLogoText: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Text(AppStrings.AppShell.appName)
            .font(.custom("Hahmlet-Bold", size: size))
            .fontWeight(.black)
            .kerning(size * 0.07)
            .scaleEffect(x: 1.08, y: 0.82, anchor: .center)
            .foregroundColor(color)
            .multilineTextAlignment(.center)
    }
}
