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
        HStack(spacing: 14) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: 28, height: 28)
                }
            } else {
                Color.clear
                    .frame(width: 28, height: 28)
            }

            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index < step ? Color.black : Color(.systemGray5))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                }
            }

            Text("\(step)/\(totalSteps)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.systemGray))
        }
    }
}
