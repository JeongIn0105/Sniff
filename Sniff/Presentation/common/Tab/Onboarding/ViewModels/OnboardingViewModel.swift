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
    @Published var selectedVibes: [String] = []    // 분위기 (최대 3개)
    @Published var selectedImages: [String] = []   // 향의 느낌 (최대 3개)

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
    let vibeTags: [String] = PreferenceTag.vibeTags.map(\.displayName)
    let imageTags: [String] = PreferenceTag.imageTags.map(\.displayName)

    init(userTasteRepository: UserTasteRepositoryType) {
        self.userTasteRepository = userTasteRepository
        bindNickname()
    }

    // MARK: - 선택 로직

    func completeOnboarding() {
        // TODO: Firestore 저장 후 홈 탭으로 이동
        currentStep = .nickname
    }

    func clearNickname() {
        nickname = ""
        nicknameValidationState = .idle
    }

    func checkNicknameDuplication() async {
        let trimmedNickname = trimmedNickname

        guard nicknameValidator.isValidFormat(trimmedNickname) else {
            nicknameValidationState = .invalid
            return
        }

        nicknameValidationState = .checking

        do {
            let isAvailable = try await userTasteRepository.checkNicknameAvailability(trimmedNickname)
            nicknameValidationState = isAvailable ? .available : .unavailable
        } catch {
            nicknameValidationState = .idle
            errorMessage = error.localizedDescription
        }
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

    // 다음 버튼 활성화 조건
    var canProceed: Bool {
        !selectedVibes.isEmpty && !selectedImages.isEmpty
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
            return "중복 여부를 확인하고 있어요..."
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
            errorMessage = "향수 경험을 먼저 선택해주세요."
            return
        }

        guard nicknameValidator.isValidFormat(trimmedNickname) else {
            nicknameValidationState = .invalid
            errorMessage = AppStrings.Nickname.invalid
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            nicknameValidationState = .available
            let result = try await userTasteRepository.analyzeTaste(input: makeTasteAnalysisInput(for: experience))
            try await userTasteRepository.saveUserProfile(
                nickname: trimmedNickname,
                tasteAnalysis: result
            )
            tasteResult = result
            currentStep = .result

        } catch {
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
        case .beginner:
            return "향수를 처음 시작했어요"
        case .casual:
            return "향수를 가끔씩 뿌려요"
        case .expert:
            return "향수를 꽤 알고 있어요"
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
    }
}
