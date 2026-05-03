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
            case .dislikedScents:
                OnboardingTagStepView(
                    step: 2,
                    title: "싫어하는 향이 있나요?",
                    subtitle: "추천에서 덜 보이도록 반영할게요. (최대 3개)",
                    groups: [(title: nil, tags: viewModel.dislikedTags)],
                    selectedTags: Set(viewModel.selectedDislikedTags),
                    maxSelectionCount: 3,
                    layout: .flow,
                    isActionEnabled: viewModel.canProceedFromDislikedTags,
                    onBack: { viewModel.currentStep = .nickname },
                    onTagTap: { viewModel.toggleDislikedTag($0) },
                    onNext: { viewModel.proceedFromDislikedTags() }
                )

            case .preferredScent:
                OnboardingTagStepView(
                    step: 3,
                    title: "끌리는 향을 골라주세요",
                    subtitle: "가장 마음에 드는 향을 골라주세요. (최대 3개)",
                    groups: viewModel.preferredScentGroups.map { (title: Optional($0.title), tags: $0.tags) },
                    selectedTags: Set(viewModel.selectedPreferredScents),
                    maxSelectionCount: 3,
                    layout: .groupedFlow,
                    isActionEnabled: viewModel.canProceedFromPreferredScents,
                    onBack: { viewModel.currentStep = .dislikedScents },
                    onTagTap: { viewModel.togglePreferredScent($0) },
                    onNext: { viewModel.currentStep = .seasonMood }
                )

            case .seasonMood:
                OnboardingTagStepView(
                    step: 4,
                    title: "어떤 계절감의 향이 끌리나요?",
                    subtitle: "가장 가까운 느낌을 골라주세요",
                    groups: [(title: nil, tags: viewModel.seasonMoodTags)],
                    selectedTags: Set([viewModel.selectedSeasonMood].compactMap { $0 }),
                    maxSelectionCount: 1,
                    layout: .verticalList,
                    isActionEnabled: viewModel.canProceedFromSeasonMood,
                    onBack: { viewModel.currentStep = .preferredScent },
                    onTagTap: { viewModel.selectSeasonMood($0) },
                    onNext: { viewModel.currentStep = .impression }
                )

            case .impression:
                OnboardingTagStepView(
                    step: 5,
                    title: "향수로 어떤 인상을 주고 싶나요?",
                    subtitle: "가장 원하는 느낌을 골라주세요. (최대 2개)",
                    groups: [(title: nil, tags: viewModel.impressionTags)],
                    selectedTags: Set(viewModel.selectedImpressions),
                    maxSelectionCount: 2,
                    layout: .twoColumnGrid,
                    isActionEnabled: viewModel.canProceedFromImpressions,
                    onBack: { viewModel.currentStep = .seasonMood },
                    onTagTap: { viewModel.toggleImpression($0) },
                    onNext: { Task { await viewModel.finishOnboardingQuestions() } }
                )

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
        .onChange(of: viewModel.didCompleteTagOnboarding) { completed in
            if completed {
                onComplete()
            }
        }
    }
}

private struct OnboardingTagStepView: View {
    let step: Int
    let title: String
    let subtitle: String
    let groups: [(title: String?, tags: [String])]
    let selectedTags: Set<String>
    let maxSelectionCount: Int
    let layout: OnboardingTagLayout
    let isActionEnabled: Bool
    let onBack: () -> Void
    let onTagTap: (String) -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(step: step, totalSteps: 5, onBack: onBack)
                .padding(.top, 24)
                .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(.black)
                        .lineSpacing(5)
                        .padding(.top, 54)

                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(hex: "#6F7683"))
                        .padding(.top, 8)

                    tagContent
                        .padding(.top, 30)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Divider()
                .background(Color(hex: "#EEF0F3"))

            Button(action: onNext) {
                Text(AppStrings.Onboarding.next)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isActionEnabled ? .black : Color(hex: "#9EA6B5"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isActionEnabled ? Color(hex: "#F1E8DF") : Color(hex: "#E2E5EA"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!isActionEnabled)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private var tagContent: some View {
        switch layout {
        case .flow:
            FlowLayout(spacing: 10) {
                ForEach(groups.flatMap(\.tags), id: \.self) { tag in
                    tagChip(tag)
                }
            }
        case .groupedFlow:
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groups.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 12) {
                        if let title = groups[index].title {
                            Text(title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "#243044"))
                        }

                        FlowLayout(spacing: 10) {
                            ForEach(groups[index].tags, id: \.self) { tag in
                                tagChip(tag)
                            }
                        }
                    }
                }
            }
        case .verticalList:
            VStack(spacing: 14) {
                ForEach(groups.flatMap(\.tags), id: \.self) { tag in
                    tagChip(tag)
                        .frame(maxWidth: .infinity)
                        .frame(height: 78)
                }
            }
        case .twoColumnGrid:
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 14
            ) {
                ForEach(groups.flatMap(\.tags), id: \.self) { tag in
                    tagChip(tag)
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                }
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        let selected = selectedTags.contains(tag)
        let noPreferenceSelected = selectedTags.contains("딱히 없어요")
        let reachedLimit = maxSelectionCount > 1 && selectedTags.count >= maxSelectionCount
        let disabled = !selected && (reachedLimit || noPreferenceSelected)

        return Button {
            onTagTap(tag)
        } label: {
            Text(tag)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(disabled ? Color(hex: "#C5CAD2") : Color(hex: "#243044"))
                .padding(.horizontal, layout.horizontalPadding)
                .frame(height: layout.chipHeight)
                .frame(maxWidth: layout.fillsWidth ? .infinity : nil)
                .background(selected ? Color(hex: "#F1E8DF") : Color.white)
                .overlay(
                    Capsule()
                        .stroke(disabled ? Color(hex: "#E6E9EE") : Color(hex: "#CBD1DA"), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}

private enum OnboardingTagLayout {
    case flow
    case groupedFlow
    case verticalList
    case twoColumnGrid

    var chipHeight: CGFloat {
        switch self {
        case .verticalList, .twoColumnGrid:
            return 72
        case .flow, .groupedFlow:
            return 44
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .verticalList, .twoColumnGrid:
            return 18
        case .flow, .groupedFlow:
            return 18
        }
    }

    var fillsWidth: Bool {
        switch self {
        case .verticalList, .twoColumnGrid:
            return true
        case .flow, .groupedFlow:
            return false
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
        .background(Color.white)
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
