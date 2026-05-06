//
//  SplashView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                SniffLogoText(
                    color: Color(red: 0.96, green: 0.91, blue: 0.87),
                    size: 38
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height * 0.45
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    SplashView()
}
