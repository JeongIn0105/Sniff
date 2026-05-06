//
//  OnboardingTasteView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import SwiftUI

struct OnboardingTasteView: View {
    enum Mode {
        case vibe
        case image
    }

    @ObservedObject var viewModel: OnboardingViewModel
    let mode: Mode
    private let contentWidth: CGFloat = 344
    private let titleConfig = TitleLayoutConfig.default

    var body: some View {
        GeometryReader { geometry in
            let resolvedContentWidth = min(contentWidth, geometry.size.width - (titleConfig.leadingInset * 2))

            VStack(alignment: .leading, spacing: 0) {
                OnboardingStepHeader(
                    step: mode == .vibe ? 3 : 4,
                    totalSteps: 4,
                    onBack: {
                        viewModel.currentStep = mode == .vibe ? .experience : .vibe
                    }
                )
                .padding(.top, 8)
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 48)

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        applyTitleConfig(mode == .vibe ? AppStrings.Onboarding.vibeTitle : AppStrings.Onboarding.imageTitle, config: titleConfig)

                        Text(mode == .vibe ? AppStrings.Onboarding.vibeSubtitle : AppStrings.Onboarding.imageSubtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                    }

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(currentTags, id: \.self) { tag in
                            TagButton(
                                title: tag,
                                isSelected: currentSelections.contains(tag),
                                isDisabled: !currentSelections.contains(tag) && currentSelections.count >= 3,
                                selectionOrder: viewModel.selectionOrder(for: tag, in: currentSelections)
                            ) {
                                toggle(tag)
                            }
                        }
                    }
                }
                .frame(maxWidth: resolvedContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)

                if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                Spacer()

                Button {
                    if mode == .vibe {
                        viewModel.currentStep = .image
                    } else {
                        Task {
                            await viewModel.analyzeTaste()
                        }
                    }
                } label: {
                    HStack {
                        if mode == .image && viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                            Text(AppStrings.Onboarding.analyzing)
                        } else {
                            Text(mode == .vibe ? AppStrings.Onboarding.next : AppStrings.Onboarding.complete)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isActionEnabled ? Color(hex: "#242424") : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(!isActionEnabled || viewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white.ignoresSafeArea())
    }

    private var currentTags: [String] {
        mode == .vibe ? viewModel.vibeTags : viewModel.imageTags
    }

    private var currentSelections: [String] {
        mode == .vibe ? viewModel.selectedVibes : viewModel.selectedImages
    }

    private var isActionEnabled: Bool {
        mode == .vibe ? viewModel.canProceedFromVibe : viewModel.canProceedFromImage
    }

    private func toggle(_ tag: String) {
        if mode == .vibe {
            viewModel.toggleVibe(tag)
        } else {
            viewModel.toggleImage(tag)
        }
    }

    private func applyTitleConfig(_ text: String, config: TitleLayoutConfig = .default) -> some View {
        Text(text)
            .font(.system(size: config.fontSize, weight: config.resolvedFontWeight))
            .foregroundColor(.black)
            .lineSpacing(config.lineSpacing)
            .multilineTextAlignment(.leading)
    }
}
