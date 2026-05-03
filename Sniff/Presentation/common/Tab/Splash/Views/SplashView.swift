//
//  SplashView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Text(AppStrings.AppShell.Splash.title)
                .font(
                    Font.custom("Hahmlet", size: 28)
                        .weight(.bold)
                )
                .kerning(2)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.95, green: 0.91, blue: 0.87))
                .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(width: 390, height: 844)
        .background(.black)
    }
}
