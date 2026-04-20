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
            // 배경 흰색
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 로고
                VStack(spacing: 12) {
                    Text("킁킁")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundStyle(.black)
                    Text("나만의 향수 취향을 찾아보세요")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                // 커스텀 Apple 로그인 버튼
                Button {
                    guard let windowScene = UIApplication.shared.connectedScenes
                        .first as? UIWindowScene,
                          let window = windowScene.windows.first else { return }
                    viewModel.signInWithApple(presentationAnchor: window)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                        Text("Apple로 로그인")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 32)
                }
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.black)
                        .padding(.top, 16)
                }
                
                Spacer().frame(height: 60)
            }
        }
        .toast(isPresented: $viewModel.showError,
               message: viewModel.errorMessage ?? "로그인에 실패했습니다.")
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
