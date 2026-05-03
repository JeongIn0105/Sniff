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
            // 배경: 전체 화면 검정
            Color.black
                .ignoresSafeArea()

            // 앱 이름: 화면 중앙에 배치
            Text(AppStrings.AppShell.Splash.title)
                .font(
                    Font.custom("Hahmlet", size: 28)
                        .weight(.bold)
                )
                .kerning(2)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.95, green: 0.91, blue: 0.87))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
    }
}

#Preview {
    SplashView()
}
