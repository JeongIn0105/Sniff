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
    private let horizontalInset: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    OnboardingStepHeader(step: 1, totalSteps: 5) {
                        isNicknameFieldFocused = false
                        onBack()
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, horizontalInset)

                    title
                        .padding(.top, geometry.size.height * 0.20)
                        .padding(.horizontal, horizontalInset)

                    nicknameInputSection
                        .padding(.top, 46)
                        .padding(.horizontal, horizontalInset)

                    Spacer()

                    Button {
                        isNicknameFieldFocused = false
                        viewModel.proceedFromNickname()
                    } label: {
                        Text(AppStrings.Nickname.confirm)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(viewModel.canProceedFromNickname ? .black : Color(hex: "#9EA6B5"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.canProceedFromNickname ? Color(hex: "#F1E8DF") : Color(hex: "#E2E5EA"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!viewModel.canProceedFromNickname)
                    .padding(.horizontal, horizontalInset)
                    .padding(.bottom, 18)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var title: some View {
        Text(AppStrings.Nickname.title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.black)
            .lineSpacing(7)
            .multilineTextAlignment(.leading)
    }

    private var nicknameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(AppStrings.Nickname.label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "#6F7683"))

                Spacer()

                Button {
                    isNicknameFieldFocused = false
                    Task {
                        await viewModel.checkNicknameDuplication()
                    }
                } label: {
                    Text(AppStrings.Nickname.duplicateCheck)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "#4D5665"))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .disabled(!viewModel.canCheckNicknameDuplication || viewModel.isLoading)
                .opacity(viewModel.canCheckNicknameDuplication && !viewModel.isLoading ? 1 : 0.55)
            }

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .frame(height: 44)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(nicknameBorderColor, lineWidth: 1)
                    }

                TextField("", text: $viewModel.nickname, prompt: Text(AppStrings.Nickname.placeholder).foregroundColor(Color(hex: "#9EA6B5")))
                    .focused($isNicknameFieldFocused)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.leading, 12)
                    .padding(.trailing, 36)
                    .frame(height: 44)

                if !viewModel.nickname.isEmpty {
                    Button {
                        viewModel.clearNickname()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.systemGray3))
                    }
                    .padding(.trailing, 12)
                }
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
                .foregroundColor(Color(hex: "#8C95A3"))

            if let welcomeMessage = viewModel.nicknameWelcomeMessage {
                Text(welcomeMessage)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8C95A3"))
                    .padding(.top, 2)
            }
        }
    }

    private var nicknameBorderColor: Color {
        switch viewModel.nicknameValidationState {
        case .invalid, .unavailable:
            return Color.red
        default:
            return Color(hex: "#D6DAE1")
        }
    }
}
