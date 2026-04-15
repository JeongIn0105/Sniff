//
//  LoginView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    let onLogin: () -> Void
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack {
            Spacer()

            Text("킁킁")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.black)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
            }

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                viewModel.prepareAppleLoginRequest(request)
            } onCompletion: { result in
                viewModel.handleAppleLoginResult(result, onSuccess: onLogin)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .disabled(viewModel.isLoading)
            .overlay(alignment: .center) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.white)
    }
}
