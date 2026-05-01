    //
    //  OnboardingResultView.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.14.
    //

import SwiftUI

struct OnboardingResultView: View {

    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    private let horizontalInset: CGFloat = 28

    var body: some View {
        Group {
            if let result = viewModel.tasteResult {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 62)

                    Text(AppStrings.Onboarding.Result.title(nickname: viewModel.nickname))
                        .font(.system(size: 23, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 26) {
                                HStack(alignment: .top, spacing: 14) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(resultAccentGradient(result: result))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                        )

                                    VStack(alignment: .leading, spacing: 7) {
                                        Text(result.displayTitle)
                                            .font(.system(size: 19, weight: .bold))
                                            .foregroundColor(.black)
                                            .lineSpacing(2)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(result.displayMajorSummary)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(.systemGray))
                                            .lineLimit(2)
                                    }
                                }

                                Text(result.analysisSummary)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color(.darkGray))
                                    .lineSpacing(7)
                                    .multilineTextAlignment(.leading)

                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 1)

                                VStack(alignment: .leading, spacing: 12) {
                                    Text(AppStrings.Onboarding.recommendationFamilies)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(.systemGray))

                                    FlowLayout(spacing: 8) {
                                        ForEach(result.recommendationDirection.preferredFamilies, id: \.self) { family in
                                            RecommendedFamilyChip(title: family)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 26)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.black.opacity(0.7), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, horizontalInset)

                            Text(AppStrings.Onboarding.Result.footnote)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(.systemGray))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, horizontalInset)
                                .padding(.top, 14)
                        }
                        .padding(.top, 36)
                        .padding(.bottom, 24)
                    }

                    Spacer(minLength: 0)

                    Button {
                        onComplete()
                    } label: {
                        Text(AppStrings.Onboarding.Result.cta)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(uiColor: UIColor(hex: "#1F1F1F")))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, horizontalInset)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.sniffBeige.ignoresSafeArea())
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView(AppStrings.Onboarding.loadingResult)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.sniffBeige.ignoresSafeArea())
            }
        }
    }

    private func resultAccentGradient(result: TasteAnalysisResult) -> LinearGradient {
        let families = result.recommendationDirection.preferredFamilies
        let first = families.first.map { Color(uiColor: ScentFamilyColor.color(for: $0)) } ?? Color.sniffBeige
        let second = families.dropFirst().first.map { Color(uiColor: ScentFamilyColor.color(for: $0)) } ?? Color.white

        return LinearGradient(
            colors: [
                first.opacity(0.55),
                second.opacity(0.35),
                Color.white.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct RecommendedFamilyChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(uiColor: ScentFamilyColor.color(for: title)).opacity(0.75))
                .frame(width: 7, height: 7)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.32), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
