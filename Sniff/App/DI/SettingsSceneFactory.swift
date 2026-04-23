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
    static func makeAccountInfoView() -> AccountInfoView {
        makeAccountInfoView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeAccountInfoView(
        dependencyContainer: AppDependencyContainer
    ) -> AccountInfoView {
        AccountInfoView(viewModel: dependencyContainer.makeAccountInfoViewModel())
    }

    @MainActor
    static func makeEmailChangeView() -> EmailChangeView {
        makeEmailChangeView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeEmailChangeView(
        dependencyContainer: AppDependencyContainer
    ) -> EmailChangeView {
        EmailChangeView(viewModel: dependencyContainer.makeEmailChangeViewModel())
    }

    @MainActor
    static func makeDeviceManageView() -> DeviceManageView {
        makeDeviceManageView(dependencyContainer: AppDependencyContainer())
    }

    @MainActor
    static func makeDeviceManageView(
        dependencyContainer: AppDependencyContainer
    ) -> DeviceManageView {
        DeviceManageView(viewModel: dependencyContainer.makeDeviceManageViewModel())
    }

    @MainActor
    static func makeWithdrawView(nickname: String) -> WithdrawView {
        WithdrawView(nickname: nickname)
    }
}
