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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            onboardingHeader
                .padding(.top, 12)
                .padding(.horizontal, 20)

            Text(AppStrings.Nickname.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
                .lineSpacing(4)
                .padding(.top, 34)
                .padding(.horizontal, 20)

            nicknameInputSection
                .padding(.top, 34)
                .padding(.horizontal, 20)

            Spacer()

            Button {
                isNicknameFieldFocused = false
                viewModel.currentStep = .experience
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
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }

    private var onboardingHeader: some View {
        HStack(spacing: 14) {
            Button {
                isNicknameFieldFocused = false
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 28, height: 28)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    Capsule()
                        .fill(Color(.systemGray))
                        .frame(width: geometry.size.width * 0.25, height: 6)
                }
            }
            .frame(height: 6)

            Text("1/4")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.systemGray))
        }
    }

    private var nicknameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
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
                    viewModel.checkNicknameDuplication()
                } label: {
                    Text(AppStrings.Nickname.duplicateCheck)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .disabled(!viewModel.canCheckNicknameDuplication)
                .opacity(viewModel.canCheckNicknameDuplication ? 1 : 0.45)
            }

            if let message = viewModel.nicknameStatusMessage {
                Text(message)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.nicknameStatusColor)
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
}
