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
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text(AppStrings.AppShell.Login.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                
                Spacer()
                
                Button {
                    let scenes = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                    guard let window = scenes
                        .flatMap(\.windows)
                        .first(where: \.isKeyWindow)
                        ?? scenes.flatMap(\.windows).first
                    else { return }
                    viewModel.signInWithApple(presentationAnchor: window)
                } label: {
                    Text(AppStrings.AppShell.Login.appleButton)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#242424"))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.horizontal, 14)
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.black)
                        .padding(.top, 12)
                }
                
                Spacer().frame(height: 42)
            }
        }
        .toast(isPresented: $viewModel.showError,
               message: viewModel.errorMessage ?? AppStrings.AppShell.Login.defaultError)
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
