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
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
