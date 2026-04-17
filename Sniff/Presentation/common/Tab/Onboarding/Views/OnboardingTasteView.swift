//
//  OnboardingTasteView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//

import SwiftUI

struct OnboardingTasteView: View {

    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            ProgressView(value: 3, total: 4)
                .padding(.horizontal)

            Text(AppStrings.Onboarding.tasteTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 분위기 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(AppStrings.Onboarding.vibeSection)
                                .font(.headline)

                            Spacer()

                            Text("\(viewModel.selectedVibes.count)/3")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 12
                        ) {
                            ForEach(viewModel.vibeTags, id: \.self) { tag in
                                TagButton(
                                    title: tag,
                                    isSelected: viewModel.selectedVibes.contains(tag),
                                    isDisabled: !viewModel.selectedVibes.contains(tag) && viewModel.selectedVibes.count >= 3
                                ) {
                                    viewModel.toggleVibe(tag)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Divider()
                        .padding(.horizontal)

                    // 향의 느낌 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(AppStrings.Onboarding.imageSection)
                                .font(.headline)

                            Spacer()

                            Text("\(viewModel.selectedImages.count)/3")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 12
                        ) {
                            ForEach(viewModel.imageTags, id: \.self) { tag in
                                TagButton(
                                    title: tag,
                                    isSelected: viewModel.selectedImages.contains(tag),
                                    isDisabled: !viewModel.selectedImages.contains(tag) && viewModel.selectedImages.count >= 3
                                ) {
                                    viewModel.toggleImage(tag)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }

            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await viewModel.analyzeTaste()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                        Text(AppStrings.Onboarding.analyzing)
                    } else {
                        Text(AppStrings.Onboarding.complete)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canProceed ? Color.black : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canProceed || viewModel.isLoading)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }
}
