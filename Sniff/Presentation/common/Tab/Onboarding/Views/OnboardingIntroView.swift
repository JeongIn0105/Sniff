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
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 60)

            Text("당신의 향수 취향을\n킁킁과 함께 발견해가요")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal)

            Spacer().frame(height: 16)

            Text("보유하고 있는 향수, 관심있는 향수를 등록하고\n나만의 향수를 추천받아 보세요")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)

            Spacer()

            Button(action: onStart) {
                Text("킁킁 시작하기")
                    .font(.body)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.white)
    }
}
