//
//  OnboardingContainerView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import SwiftUI
import Combine

struct OnboardingContainerView: View {

    @StateObject private var viewModel: OnboardingViewModel
    let onBack: () -> Void
    let onComplete: () -> Void

    init(
        viewModel: OnboardingViewModel,
        onBack: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onBack = onBack
        self.onComplete = onComplete
    }

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .nickname:
                OnboardingNicknameView(viewModel: viewModel, onBack: onBack)

            case .experience:
                OnboardingExperienceView(viewModel: viewModel)

            case .vibe:
                OnboardingTasteView(viewModel: viewModel, mode: .vibe)

            case .image:
                OnboardingTasteView(viewModel: viewModel, mode: .image)

            case .loadingResult:
                OnboardingLoadingView()

            case .result:
                OnboardingResultView(viewModel: viewModel, onComplete: onComplete)
            }
        }
    }
}

private struct OnboardingLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(AppStrings.Onboarding.loadingTitle)
                .font(.title3.weight(.semibold))

            AnimatedDotsView()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct AnimatedDotsView: View {
    @State private var activeIndex = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Text(".")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.secondary)
                    .opacity(index <= activeIndex ? 1 : 0.25)
                    .scaleEffect(index == activeIndex ? 1.05 : 1)
                    .animation(.easeInOut(duration: 0.2), value: activeIndex)
            }
        }
        .onReceive(timer) { _ in
            activeIndex = (activeIndex + 1) % 3
        }
    }
}
