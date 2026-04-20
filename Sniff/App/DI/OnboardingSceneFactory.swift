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
        let viewModel = OnboardingViewModel(userTasteRepository: UserTasteRepository())
        return OnboardingContainerView(
            viewModel: viewModel,
            onBack: onBack,
            onComplete: onComplete
        )
    }
}
