//
//  OnboardingNicknameView.swift
//  Sniff
//
//  Created by Codex on 2026.04.15.
//

import SwiftUI

struct OnboardingNicknameView: View {

    @ObservedObject var viewModel: OnboardingViewModel
    let onBack: () -> Void
    @FocusState private var isNicknameFieldFocused: Bool
    private let contentWidth: CGFloat = 344
    private let titleConfig = TitleLayoutConfig.default

    var body: some View {
        GeometryReader { geometry in
            let resolvedContentWidth = min(contentWidth, geometry.size.width - (titleConfig.leadingInset * 2))

            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    onboardingHeader
                        .padding(.top, 8)
                        .padding(.horizontal, 20)

                    Spacer()

                    Button {
                        isNicknameFieldFocused = false
                        viewModel.proceedFromNickname()
                    } label: {
                        Text(AppStrings.Nickname.confirm)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.canProceedFromNickname ? Color.black : Color(.systemGray4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!viewModel.canProceedFromNickname)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                VStack(alignment: .leading, spacing: 32) {
                    applyTitleConfig(AppStrings.Nickname.title, config: titleConfig)

                    nicknameInputSection
                }
                .frame(maxWidth: resolvedContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, geometry.size.height * 0.26)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.sniffBeige.ignoresSafeArea())
    }

    private var onboardingHeader: some View {
        OnboardingStepHeader(step: 1, totalSteps: 4) {
            isNicknameFieldFocused = false
            onBack()
        }
    }

    private var nicknameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.9))
                        .frame(height: 48)

                    TextField("", text: $viewModel.nickname, prompt: Text(AppStrings.Nickname.placeholder).foregroundColor(Color(.systemGray3)))
                        .focused($isNicknameFieldFocused)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(.leading, 14)
                        .padding(.trailing, 38)
                        .frame(height: 48)

                    if !viewModel.nickname.isEmpty {
                        Button {
                            viewModel.clearNickname()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(.systemGray))
                        }
                        .padding(.trailing, 12)
                    }
                }

                Button {
                    isNicknameFieldFocused = false
                    Task {
                        await viewModel.checkNicknameDuplication()
                    }
                } label: {
                    Text(AppStrings.Nickname.duplicateCheck)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .disabled(!viewModel.canCheckNicknameDuplication || viewModel.isLoading)
                .opacity(viewModel.canCheckNicknameDuplication && !viewModel.isLoading ? 1 : 0.45)
            }

            if let message = viewModel.nicknameStatusMessage {
                Text(message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.nicknameStatusColor)
            }

            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(AppStrings.Nickname.description)
                .font(.system(size: 12))
                .foregroundColor(Color(.systemGray))

            if let welcomeMessage = viewModel.nicknameWelcomeMessage {
                Text(welcomeMessage)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.systemGray))
                    .padding(.top, 2)
            }
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
