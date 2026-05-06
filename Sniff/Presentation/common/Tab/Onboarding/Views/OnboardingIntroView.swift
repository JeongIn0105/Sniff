//
//  OnboardingIntroView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct OnboardingIntroView: View {
    let onStart: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let topTextInset = geometry.size.height * 0.17

            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: topTextInset)

                    Text(AppStrings.AppShell.Intro.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: "#242424"))
                        .lineSpacing(6)

                    Text(AppStrings.AppShell.Intro.subtitle)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(hex: "#6F6F6F"))
                        .lineSpacing(7)
                        .padding(.top, 16)

                    Spacer()

                    Image("onboarding_perfumes")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: min(geometry.size.height * 0.28, 238))
                        .padding(.horizontal, -2)
                        .padding(.bottom, 42)

                    Button(action: onStart) {
                        Text(AppStrings.AppShell.Intro.start)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "#242424"))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.bottom, 50)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
            }
        }
    }
}
