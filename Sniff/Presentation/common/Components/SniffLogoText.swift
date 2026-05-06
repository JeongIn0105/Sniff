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
            .font(.custom("Hahmlet-Black", size: size * 1.12))
            .fontWeight(.black)
            .kerning(size * 0.04)
            .foregroundColor(color)
            .multilineTextAlignment(.center)
    }
}
