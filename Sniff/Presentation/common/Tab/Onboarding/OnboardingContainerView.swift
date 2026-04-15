//
//  OnboardingContainerView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import SwiftUI

struct OnboardingContainerView: View {

    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .experience:
                OnboardingExperienceView(viewModel: viewModel)

            case .taste:
                OnboardingTasteView(viewModel: viewModel)

            case .result:
                OnboardingResultView(viewModel: viewModel)
            }
        }
    }
}

