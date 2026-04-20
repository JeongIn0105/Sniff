//
//  LoginSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import SwiftUI

enum LoginSceneFactory {

    static func makeView(
        onNewUser: @escaping () -> Void,
        onExistingUser: @escaping () -> Void
    ) -> LoginView {
        let viewModel = LoginViewModel(
            authService: AuthService.shared,
            userProfileStatusRepository: UserProfileStatusRepository(),
            appleSignInHelper: AppleSignInHelper(),
            onNewUser: onNewUser,
            onExistingUser: onExistingUser
        )
        return LoginView(viewModel: viewModel)
    }
}
