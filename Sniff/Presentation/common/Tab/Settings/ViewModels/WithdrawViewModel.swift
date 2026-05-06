//
//  WithdrawViewModel.swift
//  Sniff
//

import Combine
import AuthenticationServices
import Foundation
import UIKit

// MARK: - 회원탈퇴 뷰모델

@MainActor
final class WithdrawViewModel: ObservableObject {

    @Published var isAgreed = false
    @Published var isLoading = false
    @Published var didWithdraw = false
    @Published var errorMessage: String?
    @Published var reauthenticationProvider: WithdrawalReauthenticationProvider?

    /// 닉네임 (화면 상단 표시용)
    let nickname: String

    private let withdrawalService: WithdrawalServiceType

    init(
        nickname: String,
        withdrawalService: WithdrawalServiceType
    ) {
        self.nickname = nickname
        self.withdrawalService = withdrawalService
    }

    // MARK: - 회원탈퇴 실행

    func withdrawAccount() async {
        guard isAgreed else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await withdrawalService.withdrawAccount()
            didWithdraw = true
        } catch WithdrawalServiceError.requiresReauthentication(let provider) {
            requestReauthentication(provider)
        } catch let error where withdrawalService.isRecentLoginError(error) {
            withdrawalService.resetReauthentication()
            errorMessage = AppStrings.ViewModelMessages.Withdraw.requiresRecentLogin
        } catch {
            errorMessage = AppStrings.ViewModelMessages.Withdraw.failed
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func clearReauthenticationRequest() {
        reauthenticationProvider = nil
    }

    func reauthenticateWithApple(presentationAnchor: ASPresentationAnchor) {
        isLoading = true
        Task {
            do {
                try await withdrawalService.reauthenticateWithApple(presentationAnchor: presentationAnchor)
                clearReauthenticationRequest()
                await withdrawAccount()
            } catch {
                isLoading = false
                clearReauthenticationRequest()
                if let authError = error as? AuthError, authError == .canceled { return }
                handleReauthenticationError(error)
            }
        }
    }

    func reauthenticateWithGoogle(presentingWindow: UIWindow) {
        isLoading = true
        Task {
            do {
                try await withdrawalService.reauthenticateWithGoogle(presentingWindow: presentingWindow)
                clearReauthenticationRequest()
                await withdrawAccount()
            } catch let error as GoogleSignInError where error == .canceled {
                isLoading = false
                clearReauthenticationRequest()
            } catch {
                isLoading = false
                clearReauthenticationRequest()
                handleReauthenticationError(error)
            }
        }
    }
}

// MARK: - 재인증 처리

private extension WithdrawViewModel {

    func requestReauthentication(_ provider: WithdrawalReauthenticationProvider) {
        reauthenticationProvider = provider
        if reauthenticationProvider == .unsupported {
            errorMessage = AppStrings.ViewModelMessages.Withdraw.requiresRecentLogin
        }
    }

    func handleReauthenticationError(_ error: Error) {
        if withdrawalService.isRecentLoginError(error) {
            errorMessage = AppStrings.ViewModelMessages.Withdraw.requiresRecentLogin
        } else {
            errorMessage = error.localizedDescription
        }
    }
}
