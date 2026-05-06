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
    private let horizontalInset: CGFloat = 34

    var body: some View {
        Group {
            if let result = viewModel.tasteResult {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        Spacer(minLength: 36)

                        resultContent(result)
                            .padding(.top, max(12, geometry.safeAreaInsets.top * 0.35))

                        Spacer(minLength: 28)

                        bottomAction
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Color.white.ignoresSafeArea())
            } else {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView(AppStrings.Onboarding.loadingResult)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.ignoresSafeArea())
            }
        }
    }

    private func resultContent(_ result: TasteAnalysisResult) -> some View {
        VStack(spacing: 0) {
            Text(AppStrings.Onboarding.Result.title(nickname: viewModel.nickname))
                .font(.system(size: 25, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .foregroundColor(.black)
                .padding(.horizontal, 32)

            resultCard(result)
                .padding(.horizontal, horizontalInset)
                .padding(.top, 32)

            Text(AppStrings.Onboarding.Result.footnote)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.systemGray))
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, horizontalInset)
                .padding(.top, 18)
        }
    }

    private func resultCard(_ result: TasteAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 24) {
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
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 12) {
                Text(AppStrings.Onboarding.recommendationFamilies)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.systemGray))

                FlowLayout(spacing: 8) {
                    ForEach(displayFamilies(for: result), id: \.self) { family in
                        RecommendedFamilyChip(title: family)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#FFFDFB"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.black.opacity(0.75), lineWidth: 1)
                )
        )
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color(hex: "#EEF0F3"))

            HStack(spacing: 10) {
                Button {
                    viewModel.beginResultReanalysis()
                } label: {
                    Text(viewModel.canReanalyzeResult ? AppStrings.Onboarding.Result.reanalyze : AppStrings.Onboarding.Result.reanalyzed)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(viewModel.canReanalyzeResult ? Color.white : Color(hex: "#E2E5EA"))
                        .foregroundColor(viewModel.canReanalyzeResult ? .black : Color(hex: "#9EA6B5"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#D8DCE3"), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                .disabled(!viewModel.canReanalyzeResult || viewModel.isLoading)

                Button {
                    onComplete()
                } label: {
                    Text(AppStrings.Onboarding.Result.cta)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "#242424"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.top, 18)
            .padding(.bottom, 18)
        }
    }

    private func resultAccentGradient(result: TasteAnalysisResult) -> LinearGradient {
        if let palette = FragranceProfileText.profileColorPalette(forTitle: result.displayTitle) {
            return LinearGradient(
                colors: [
                    Color(hex: palette.accentHex).opacity(0.55),
                    Color(hex: palette.primaryHex).opacity(0.42),
                    Color(hex: palette.baseHex).opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        let families = displayFamilies(for: result)
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

    private func displayFamilies(for result: TasteAnalysisResult) -> [String] {
        FragranceProfileText.profileFamilies(forTitle: result.displayTitle)
            ?? result.recommendationDirection.preferredFamilies
    }
}

private struct RecommendedFamilyChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(uiColor: ScentFamilyColor.color(for: title)).opacity(0.75))
                .frame(width: 7, height: 7)

            Text(PerfumeKoreanTranslator.koreanFamily(for: title))
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
