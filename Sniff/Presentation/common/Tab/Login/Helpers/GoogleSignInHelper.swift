//
//  GoogleSignInHelper.swift
//  Sniff
//
//  Created by 이정인 on 2026.05.01.
//

import Foundation
import UIKit
import GoogleSignIn

// MARK: - 구글 로그인 페이로드

struct GoogleSignInPayload {
    /// Firebase OAuthCredential 생성에 사용할 ID 토큰
    let idToken: String
    /// Firebase OAuthCredential 생성에 사용할 액세스 토큰
    let accessToken: String
}

// MARK: - 구글 로그인 헬퍼

/// GoogleSignIn SDK를 통해 로그인을 처리하는 헬퍼입니다.
/// 반환된 GoogleSignInPayload를 AuthService.signInWithGoogle()에 전달하세요.
///
/// ⚠️ 사전 설정 필요:
/// 1. GoogleService-Info.plist가 프로젝트에 포함되어 있어야 합니다.
/// 2. Info.plist에 REVERSED_CLIENT_ID를 URL Scheme으로 추가해야 합니다.
/// 3. Firebase Console → Authentication → Sign-in method → Google 활성화
final class GoogleSignInHelper {

    // MARK: - 로그인 시작

    /// 구글 로그인을 시작합니다.
    /// - Parameter presentingWindow: 로그인 시트를 표시할 UIWindow
    func startSignIn(presentingWindow: UIWindow) async throws -> GoogleSignInPayload {
        guard let rootViewController = presentingWindow.rootViewController else {
            throw GoogleSignInError.missingViewController
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                    if let error {
                        // GIDSignInError로 캐스팅해서 취소 여부를 판단합니다.
                        if let signInError = error as? GIDSignInError,
                           signInError.code == .canceled {
                            continuation.resume(throwing: GoogleSignInError.canceled)
                            return
                        }
                        continuation.resume(throwing: error)
                        return
                    }
                    guard
                        let idToken = result?.user.idToken?.tokenString,
                        let accessToken = result?.user.accessToken.tokenString
                    else {
                        continuation.resume(throwing: GoogleSignInError.missingTokens)
                        return
                    }
                    continuation.resume(returning: GoogleSignInPayload(
                        idToken: idToken,
                        accessToken: accessToken
                    ))
                }
            }
        }
    }
}

// MARK: - 구글 로그인 에러

enum GoogleSignInError: LocalizedError, Equatable {
    case missingViewController
    case missingTokens
    case canceled

    var errorDescription: String? {
        switch self {
        case .missingViewController:
            return "로그인 화면을 찾을 수 없어요"
        case .missingTokens:
            return "구글 로그인 토큰을 받지 못했어요"
        case .canceled:
            return nil // 취소는 사용자 의도이므로 에러 메시지 없음
        }
    }
}
