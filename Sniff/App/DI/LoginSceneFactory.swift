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
        makeView(
            dependencyContainer: AppDependencyContainer(),
            onNewUser: onNewUser,
            onExistingUser: onExistingUser
        )
    }

    static func makeView(
        dependencyContainer: AppDependencyContainer,
        onNewUser: @escaping () -> Void,
        onExistingUser: @escaping () -> Void
    ) -> LoginView {
        let viewModel = LoginViewModel(
            authService: dependencyContainer.authService,
            userProfileStatusRepository: dependencyContainer.makeUserProfileStatusRepository(),
            appleSignInHelper: AppleSignInHelper(),
            googleSignInHelper: GoogleSignInHelper(),
            onNewUser: onNewUser,
            onExistingUser: onExistingUser
        )
        return LoginView(viewModel: viewModel)
    }
}
