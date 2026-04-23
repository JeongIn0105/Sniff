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
        WithdrawView(nickname: nickname)
    }
}
