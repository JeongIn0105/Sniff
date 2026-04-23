//
//  OnboardingViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {

    enum NicknameValidationState: Equatable {
        case idle
        case checking
        case invalid
        case available
        case unavailable
    }

    // MARK: - 온보딩 단계
    @Published var currentStep: OnboardingStep = .nickname

    // MARK: - 유저 선택 데이터
    @Published var selectedExperience: ExperienceLevel? = nil
    @Published var selectedVibes: [String] = []
    @Published var selectedImages: [String] = []

    // MARK: - Gemini 결과
    @Published var tasteResult: TasteAnalysisResult? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var nickname: String = ""
    @Published private(set) var nicknameValidationState: NicknameValidationState = .idle

    private let nicknameValidator = NicknameValidator()
    private let userTasteRepository: UserTasteRepositoryType
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 태그 목록
    let vibeTags: [String] = AppStrings.Onboarding.vibeTags
    let imageTags: [String] = AppStrings.Onboarding.imageTags

    init(userTasteRepository: UserTasteRepositoryType) {
        self.userTasteRepository = userTasteRepository
        bindNickname()
    }

    // MARK: - 선택 로직
    func completeOnboarding() {
        currentStep = .nickname
    }

    func clearNickname() {
        nickname = ""
        nicknameValidationState = .idle
        errorMessage = nil
    }

    func checkNicknameDuplication() async {
        let trimmedNickname = trimmedNickname

        guard
            nicknameValidator
            .isValidFormat(trimmedNickname) else {
            nicknameValidationState = .invalid
            return
        }

        nicknameValidationState = .checking
        errorMessage = nil

        do {
            let isAvailable = try await userTasteRepository.checkNicknameAvailability(trimmedNickname)
            nicknameValidationState = isAvailable ? .available : .unavailable
            if isAvailable {
                errorMessage = nil
            }
        } catch {
            nicknameValidationState = .idle
            errorMessage = error.localizedDescription
        }
    }

    func proceedFromNickname() {
        guard nicknameValidationState == .available else { return }
        errorMessage = nil
        currentStep = .experience
    }

    func toggleVibe(_ vibe: String) {
        if selectedVibes.contains(vibe) {
            selectedVibes.removeAll { $0 == vibe }
        } else if selectedVibes.count < 3 {
            selectedVibes.append(vibe)
        }
    }

    func toggleImage(_ image: String) {
        if selectedImages.contains(image) {
            selectedImages.removeAll { $0 == image }
        } else if selectedImages.count < 3 {
            selectedImages.append(image)
        }
    }

    func selectionOrder(for tag: String, in tags: [String]) -> Int? {
        guard let index = tags.firstIndex(of: tag) else { return nil }
        return index + 1
    }

    var canProceed: Bool {
        !selectedVibes.isEmpty && !selectedImages.isEmpty
    }

    var canProceedFromVibe: Bool {
        !selectedVibes.isEmpty
    }

    var canProceedFromImage: Bool {
        !selectedImages.isEmpty
    }

    var canCheckNicknameDuplication: Bool {
        !trimmedNickname.isEmpty
    }

    var canSubmitNickname: Bool {
        !trimmedNickname.isEmpty && !isLoading
    }

    var canProceedFromNickname: Bool {
        nicknameValidationState == .available
    }

    var nicknameStatusMessage: String? {
        switch nicknameValidationState {
        case .idle:
            return nil
        case .checking:
            return AppStrings.ViewModelMessages.Onboarding.nicknameChecking
        case .invalid:
            return AppStrings.Nickname.invalid
        case .available:
            return AppStrings.Nickname.available
        case .unavailable:
            return AppStrings.Nickname.unavailable
        }
    }

    var nicknameStatusColor: Color {
        switch nicknameValidationState {
        case .available:
            return Color.green
        case .checking:
            return Color(.systemGray)
        case .invalid, .unavailable:
            return Color.red
        case .idle:
            return Color.clear
        }
    }

    var nicknameWelcomeMessage: String? {
        guard nicknameValidationState == .available else { return nil }
        return AppStrings.Nickname.welcome(nickname: trimmedNickname)
    }

    // MARK: - Gemini API 호출
    func analyzeTaste() async {
        guard let experience = selectedExperience else {
            errorMessage = AppStrings.ViewModelMessages.Onboarding.missingExperience
            return
        }

        guard nicknameValidator.isValidFormat(trimmedNickname) else {
            nicknameValidationState = .invalid
            errorMessage = AppStrings.Nickname.invalid
            return
        }

        isLoading = true
        errorMessage = nil
        currentStep = .loadingResult

        do {
            nicknameValidationState = .available
            let result = try await userTasteRepository.analyzeTaste(input: makeTasteAnalysisInput(for: experience))
            tasteResult = result
            currentStep = .result

            do {
                try await userTasteRepository.saveUserProfile(
                    nickname: trimmedNickname,
                    tasteAnalysis: result,
                    experienceLevel: experience.rawValue
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        } catch {
            currentStep = .image
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func confirmNicknameAndProceed() async {
        let trimmedNickname = trimmedNickname

        guard nicknameValidator.isValidFormat(trimmedNickname) else {
            nicknameValidationState = .invalid
            errorMessage = AppStrings.Nickname.invalid
            return
        }

        isLoading = true
        errorMessage = nil
        nicknameValidationState = .checking

        defer { isLoading = false }

        do {
            let isAvailable = try await userTasteRepository.checkNicknameAvailability(trimmedNickname)

            guard isAvailable else {
                nicknameValidationState = .unavailable
                errorMessage = AppStrings.Nickname.unavailable
                return
            }

            nicknameValidationState = .available
            currentStep = .experience
        } catch {
            nicknameValidationState = .idle
            errorMessage = error.localizedDescription
        }
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeTasteAnalysisInput(for experience: ExperienceLevel) -> TasteAnalysisInput {
        TasteAnalysisInput(
            experience: experienceText(for: experience),
            vibes: selectedVibes,
            images: selectedImages
        )
    }

    private func experienceText(for experience: ExperienceLevel) -> String {
        switch experience {
        case .beginner: return AppStrings.ViewModelMessages.Onboarding.beginnerExperience
        case .casual: return AppStrings.ViewModelMessages.Onboarding.casualExperience
        case .expert: return AppStrings.ViewModelMessages.Onboarding.expertExperience
        }
    }

    private func bindNickname() {
        $nickname
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.sanitizeNicknameInput(newValue)
            }
            .store(in: &cancellables)
    }

    private func sanitizeNicknameInput(_ value: String) {
        let filtered = nicknameValidator.sanitize(value)

        if filtered != value {
            nickname = filtered
            return
        }

        nicknameValidationState = .idle
        errorMessage = nil
    }
}
