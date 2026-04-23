//
//  OnboardingIntroView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct OnboardingIntroView: View {
    let onStart: () -> Void
    private let contentWidth: CGFloat = 344
    private let titleConfig = TitleLayoutConfig.default

    var body: some View {
        GeometryReader { geometry in
            let resolvedContentWidth = min(contentWidth, geometry.size.width - (titleConfig.leadingInset * 2))

            ZStack {
                VStack(alignment: .leading, spacing: 16) {
                    applyTitleConfig(AppStrings.AppShell.Intro.title, config: titleConfig)

                    Text(AppStrings.AppShell.Intro.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .lineSpacing(3)
                }
                .frame(maxWidth: resolvedContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, geometry.size.height * 0.26)

                VStack(spacing: 0) {
                    Spacer()

                    Button(action: onStart) {
                        Text(AppStrings.AppShell.Intro.start)
                            .font(.body)
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.sniffBeige.ignoresSafeArea())
    }

    private func applyTitleConfig(_ text: String, config: TitleLayoutConfig = .default) -> some View {
        Text(text)
            .font(.system(size: config.fontSize, weight: config.resolvedFontWeight))
            .foregroundColor(.black)
            .multilineTextAlignment(.leading)
            .lineSpacing(config.lineSpacing)
    }
}
