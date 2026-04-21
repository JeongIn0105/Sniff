//
//  OnboardingSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import SwiftUI

enum OnboardingSceneFactory {

    static func makeView(
        onBack: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) -> OnboardingContainerView {
        makeView(
            dependencyContainer: AppDependencyContainer(),
            onBack: onBack,
            onComplete: onComplete
        )
    }

    static func makeView(
        dependencyContainer: AppDependencyContainer,
        onBack: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) -> OnboardingContainerView {
        let viewModel = OnboardingViewModel(
            userTasteRepository: dependencyContainer.makeUserTasteRepository()
        )
        return OnboardingContainerView(
            viewModel: viewModel,
            onBack: onBack,
            onComplete: onComplete
        )
    }
}
