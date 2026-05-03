//
//  OnboardingStepHeader.swift
//  Sniff
//
//  Created by Codex on 2026.04.23.
//

import SwiftUI

struct OnboardingStepHeader: View {
    let step: Int
    let totalSteps: Int
    let onBack: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 24, height: 32)
                }
            } else {
                Color.clear
                    .frame(width: 24, height: 32)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#F3F3F3"))

                    Capsule()
                        .fill(Color(hex: "#F1E8DF"))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 14)

            Text("\(step)/\(totalSteps)")
                .font(.system(size: 23, weight: .regular))
                .foregroundColor(Color(hex: "#9EA6B5"))
                .frame(width: 42, alignment: .trailing)
        }
    }

    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return min(max(CGFloat(step) / CGFloat(totalSteps), 0), 1)
    }
}
