//
//  LoginView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import AuthenticationServices

// MARK: - 로그인 화면
struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.26)

                    Text(AppStrings.AppShell.Login.title)
                        .font(
                            Font.custom("Hahmlet", size: 28)
                                .weight(.bold)
                        )
                        .kerning(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .top)

                    Spacer()

                    googleLoginButton {
                        guard let window = keyWindow else { return }
                        viewModel.signInWithGoogle(presentingWindow: window)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 12)

                    loginButton(
                        action: {
                            guard let window = keyWindow else { return }
                            viewModel.signInWithApple(presentationAnchor: window)
                        },
                        label: AppStrings.AppShell.Login.appleButton
                    )
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                            .padding(.top, 12)
                    }

                    Spacer()
                        .frame(height: 56)
                }
            }
        }
        .toast(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage ?? AppStrings.AppShell.Login.defaultError
        )
    }
    // MARK: - 공용 로그인 버튼 빌더

    private var keyWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        return scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
            ?? scenes.flatMap(\.windows).first
    }

    @ViewBuilder
    private func googleLoginButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image("google_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)

                Text(AppStrings.AppShell.Login.googleButton)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 57)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#E5E5E5"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func loginButton(
        action: @escaping () -> Void,
        label: String
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 57)
            .background(Color(hex: "#242424"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - 토스트
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isPresented {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.gray.opacity(0.9), in: Capsule())
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { isPresented = false }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}

// MARK: - Preview
#Preview {
    LoginSceneFactory.makeView(onNewUser: {}, onExistingUser: {})
}
