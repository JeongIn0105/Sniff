//
//  OnboardingResultView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import SwiftUI

struct OnboardingResultView: View {

    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        Group {
            if let result = viewModel.tasteResult {
                VStack(spacing: 32) {

                    Spacer()

                    // 타이틀
                    Text(AppStrings.Onboarding.Result.title(nickname: viewModel.nickname))
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // 취향 카드
                    VStack(spacing: 20) {

                        // 주 취향 유형명
                        Text(result.primaryProfileName)
                            .font(.title3)
                            .bold()

                        Divider()

                        // 분석 요약
                        Text(result.analysisSummary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Divider()

                        // 추천 향 계열
                        VStack(spacing: 8) {
                            Text("추천 향 계열")
                                .font(.caption)
                                .foregroundColor(.gray)

                            FlowLayout(spacing: 8) {
                                ForEach(result.recommendationDirection.preferredFamilies, id: \.self) { family in
                                    Text(family)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.black.opacity(0.05))
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 12)
                    )
                    .padding(.horizontal)

                    // 보조 취향
                    Text("보조 취향: \(result.secondaryProfileName)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Spacer()

                    // CTA 버튼
                    Button {
                        viewModel.completeOnboarding()
                    } label: {
                        Text(AppStrings.Onboarding.Result.cta)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView("결과를 불러오는 중이에요")
                    Spacer()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y
                ),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
