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
            Color.sniffBeige
                .ignoresSafeArea()

            Text(AppStrings.AppShell.Splash.title)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)
        }
    }
}
