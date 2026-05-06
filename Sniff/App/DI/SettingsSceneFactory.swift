//
//  SettingsSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import Foundation
import SwiftUI

enum SettingsSceneFactory {

    @MainActor
    static func makeSettingsView() -> SettingsView {
        makeSettingsView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeSettingsView(
        dependencyContainer: AppDependencyContainer
    ) -> SettingsView {
        SettingsView(viewModel: dependencyContainer.makeSettingsViewModel())
    }

    @MainActor
    static func makeWithdrawView(nickname: String) -> WithdrawView {
        let container = AppDependencyContainer.shared
        let withdrawalService = WithdrawalService(
            authService: container.authService,
            appleSignInHelper: AppleSignInHelper(),
            googleSignInHelper: GoogleSignInHelper(),
            coreDataStack: container.coreDataStack
        )
        let viewModel = WithdrawViewModel(
            nickname: nickname,
            withdrawalService: withdrawalService
        )
        return WithdrawView(viewModel: viewModel)
    }
}
