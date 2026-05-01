//
//  OnboardingExperienceView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import SwiftUI

struct OnboardingExperienceView: View {

    @ObservedObject var viewModel: OnboardingViewModel
    private let options = OnboardingExperienceOption.all
    private let contentWidth: CGFloat = 344
    private let titleConfig = TitleLayoutConfig.default

    var body: some View {
        GeometryReader { _ in
            let resolvedContentWidth = contentWidth

            VStack(alignment: .leading, spacing: 0) {
                OnboardingStepHeader(step: 2, totalSteps: 4) {
                    viewModel.currentStep = .nickname
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 0) {
                    applyTitleConfig(AppStrings.Onboarding.experienceTitle, config: titleConfig)
                        .padding(.top, 48)

                    VStack(spacing: 12) {
                        ForEach(options) { option in
                            Button {
                                viewModel.selectedExperience = option.level
                            } label: {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.title)
                                            .font(.body)
                                            .bold()
                                            .foregroundColor(.black)

                                        Text(option.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            viewModel.selectedExperience == option.level
                                            ? Color.sniffBeige
                                            : Color.white
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.selectedExperience == option.level
                                            ? Color.black
                                            : Color(.systemGray4),
                                            lineWidth: viewModel.selectedExperience == option.level ? 2 : 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 24)
                }
                .frame(maxWidth: resolvedContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                Button {
                    viewModel.currentStep = .vibe
                } label: {
                    Text(AppStrings.Onboarding.next)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            viewModel.selectedExperience != nil
                            ? Color.black
                            : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(viewModel.selectedExperience == nil)
                .padding(.horizontal, 24)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white.ignoresSafeArea())
    }

    private func applyTitleConfig(_ text: String, config: TitleLayoutConfig = .default) -> some View {
        Text(text)
            .font(.system(size: config.fontSize, weight: config.resolvedFontWeight))
            .foregroundColor(.black)
            .lineSpacing(config.lineSpacing)
            .multilineTextAlignment(.leading)
    }
}
