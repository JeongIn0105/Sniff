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

    var body: some View {
        Group {
            if let result = viewModel.tasteResult {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 72)

                    Text(AppStrings.Onboarding.Result.title(nickname: viewModel.nickname))
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(spacing: 0) {
                                    Text(result.displayTitle)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(2)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(maxWidth: .infinity)

                                Divider()

                                Text(result.analysisSummary)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(.systemGray))
                                    .lineSpacing(5)
                                    .multilineTextAlignment(.leading)

                                Divider()

                                VStack(alignment: .leading, spacing: 12) {
                                    Text(AppStrings.Onboarding.recommendationFamilies)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(.systemGray))

                                    FlowLayout(spacing: 10) {
                                        ForEach(result.recommendationDirection.preferredFamilies, id: \.self) { family in
                                            RecommendedFamilyChip(title: family)
                                        }
                                    }
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.white.opacity(0.94))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 28)
                                            .stroke(Color.black, lineWidth: 1.2)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 34)
                        .padding(.bottom, 24)
                    }

                    Spacer(minLength: 0)

                    Button {
                        onComplete()
                    } label: {
                        Text(AppStrings.Onboarding.Result.cta)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
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
}

private struct RecommendedFamilyChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.scentFloral.opacity(0.75))
                .frame(width: 7, height: 7)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.9))
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.45), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
