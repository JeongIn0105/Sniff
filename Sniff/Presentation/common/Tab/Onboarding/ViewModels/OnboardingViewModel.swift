//
//  OnboardingViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

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
    @Published var selectedDislikedTags: [String] = []
    @Published var selectedPreferredScents: [String] = []
    @Published var selectedSeasonMood: String?
    @Published var selectedImpressions: [String] = []
    @Published var didCompleteTagOnboarding = false

    // MARK: - Gemini 결과
    @Published var tasteResult: TasteAnalysisResult? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var nickname: String = ""
    @Published private(set) var nicknameValidationState: NicknameValidationState = .idle
    @Published private(set) var canReanalyzeResult: Bool = true
    private var isReanalyzingResult = false

    private let nicknameValidator = NicknameValidator()
    private let userTasteRepository: UserTasteRepositoryType
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 태그 목록
    let vibeTags: [String] = AppStrings.Onboarding.vibeTags
    let imageTags: [String] = AppStrings.Onboarding.imageTags
    let dislikedTags = [
        "너무 달달한 향", "머리 아픈 진한 향", "할머니 화장품 같은 향", "남자 스킨 같은 향",
        "절 냄새 같은 향", "담배/스모키한 향", "비누향", "꽃집 같은 향",
        "과일주스 같은 향", "풀 냄새 같은 향", "나무 냄새 같은 향", "바닐라 같은 향",
        "머스크 향", "화장품 가루 같은 향", "매운 향신료 같은 향", "가죽 같은 향",
        "흙/이끼 같은 향", "딱히 없어요"
    ]
    let preferredScentGroups: [(title: String, tags: [String])] = [
        (
            "깨끗하고 산뜻한 향",
            ["상큼한 레몬 향", "방금 씻은 듯한 향", "싱그러운 풀잎 향", "맑은 허브 향", "깨끗한 섬유유연제 향"]
        ),
        (
            "은은한 꽃 향",
            ["장미꽃 향", "라일락 향", "복숭아꽃 향", "포근한 목련 향", "진한 재스민 향"]
        ),
        (
            "따뜻하고 달콤한 향",
            ["달달한 바닐라 향", "포근한 머스크 향", "달콤한 꿀 향", "고소한 카라멜 향", "따뜻한 코코아 향"]
        ),
        (
            "차분한 숲과 나무 향",
            ["마른 나무 향", "비 온 뒤 숲 향", "이끼 낀 숲 향", "따뜻한 차 향", "묵직한 우드 향"]
        )
    ]
    var preferredScentTags: [String] {
        preferredScentGroups.flatMap(\.tags)
    }
    let seasonMoodTags = ["산뜻한 향", "시원한 향", "차분한 향", "포근한 향", "사계절 무난한 향"]
    let impressionTags = [
        "깨끗한 사람", "포근한 사람", "센스 있는 사람", "차분한 사람", "다정한 사람",
        "상큼한 사람", "고급스러운 사람", "자연스러운 사람", "은은한 사람"
    ]

    init(userTasteRepository: UserTasteRepositoryType) {
        self.userTasteRepository = userTasteRepository
        bindNickname()
    }

    // MARK: - 선택 로직
    func completeOnboarding() {
        currentStep = .nickname
    }

    func toggleDislikedTag(_ tag: String) {
        if tag == "딱히 없어요" {
            selectedDislikedTags = selectedDislikedTags.contains(tag) ? [] : [tag]
            return
        }

        selectedDislikedTags.removeAll { $0 == "딱히 없어요" }
        if selectedDislikedTags.contains(tag) {
            selectedDislikedTags.removeAll { $0 == tag }
        } else if selectedDislikedTags.count < 3 {
            selectedDislikedTags.append(tag)
        }
    }

    func proceedFromDislikedTags() {
        currentStep = .preferredScent
    }

    func togglePreferredScent(_ tag: String) {
        if selectedPreferredScents.contains(tag) {
            selectedPreferredScents.removeAll { $0 == tag }
        } else if selectedPreferredScents.count < 3 {
            selectedPreferredScents.append(tag)
        }
    }

    func selectSeasonMood(_ tag: String) {
        selectedSeasonMood = tag
    }

    func toggleImpression(_ tag: String) {
        if selectedImpressions.contains(tag) {
            selectedImpressions.removeAll { $0 == tag }
        } else if selectedImpressions.count < 2 {
            selectedImpressions.append(tag)
        }
    }

    func finishOnboardingQuestions() async {
        guard canProceedFromImpressions else { return }
        let didSave = await saveTagOnboarding()
        if didSave && isReanalyzingResult {
            canReanalyzeResult = false
            isReanalyzingResult = false
        }
    }

    func beginResultReanalysis() {
        guard canReanalyzeResult, !isLoading, currentStep == .result else { return }
        isReanalyzingResult = true
        errorMessage = nil
        currentStep = .dislikedScents
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
        currentStep = .dislikedScents
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

    var canProceedFromDislikedTags: Bool {
        !selectedDislikedTags.isEmpty
    }

    var canProceedFromPreferredScents: Bool {
        !selectedPreferredScents.isEmpty
    }

    var canProceedFromSeasonMood: Bool {
        selectedSeasonMood != nil
    }

    var canProceedFromImpressions: Bool {
        !selectedImpressions.isEmpty
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
            currentStep = .dislikedScents
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

    @discardableResult
    private func saveTagOnboarding(failureStep: OnboardingStep = .impression) async -> Bool {
        isLoading = true
        errorMessage = nil
        currentStep = .loadingResult
        defer { isLoading = false }

        let result = makeTagTasteAnalysisResult()
        do {
            try await userTasteRepository.saveUserProfile(
                nickname: trimmedNickname.isEmpty ? (Auth.auth().currentUser?.displayName ?? "킁킁러") : trimmedNickname,
                tasteAnalysis: result,
                experienceLevel: "tag_onboarding"
            )
            tasteResult = result
            currentStep = .result
            return true
        } catch {
            currentStep = failureStep
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func makeTagTasteAnalysisResult() -> TasteAnalysisResult {
        let preferredFamilies = OnboardingTagMapper.preferredFamilies(
            preferred: selectedPreferredScents,
            season: selectedSeasonMood,
            impression: selectedImpressions
        )
        let scentVector = Dictionary(uniqueKeysWithValues: preferredFamilies.enumerated().map {
            ($0.element, max(0.1, 1.0 - Double($0.offset) * 0.18))
        })
        let title = FragranceProfileText.profileTitle(
            originalTitle: nil,
            scentVector: scentVector,
            stage: .onboardingOnly
        )
        let cleanDislikes = selectedDislikedTags.filter { $0 != "딱히 없어요" }

        return TasteAnalysisResult(
            tasteTitle: title,
            analysisSummary: makeTagAnalysisSummary(
                preferredScents: selectedPreferredScents,
                seasonMood: selectedSeasonMood,
                impressions: selectedImpressions,
                dislikedTags: cleanDislikes,
                preferredFamilies: preferredFamilies
            ),
            evidenceTags: EvidenceTags(
                experience: selectedSeasonMood ?? "",
                vibes: selectedPreferredScents + selectedImpressions,
                images: cleanDislikes
            ),
            recommendationDirection: RecommendationDirection(
                preferredImpression: selectedImpressions + [selectedSeasonMood].compactMap { $0 },
                preferredFamilies: preferredFamilies,
                intensityLevel: selectedSeasonMood ?? "",
                safeStartingPoint: makeSafeStartingPoint(
                    preferredScents: selectedPreferredScents,
                    seasonMood: selectedSeasonMood,
                    dislikedTags: cleanDislikes
                )
            ),
            dislikedTags: cleanDislikes
        )
    }

    private func makeTagAnalysisSummary(
        preferredScents: [String],
        seasonMood: String?,
        impressions: [String],
        dislikedTags: [String],
        preferredFamilies: [String]
    ) -> String {
        let scentText = joinedDisplayText(preferredScents, fallback: "선택한 향")
        let impressionText = joinedDisplayText(impressions, fallback: "자연스러운 인상")
        let seasonText = seasonMood ?? "무난한 계절감"
        let familyText = FragranceProfileText.majorFamilySummary(for: preferredFamilies)

        var summary = "\(scentText)을 끌리는 향으로 고르고, \(seasonText)의 분위기를 선호해 \(familyText)이 잘 맞는 편이에요. \(impressionText)처럼 느껴지는 향을 좋아해서 너무 튀기보다는 취향이 자연스럽게 드러나는 향을 추천할게요."

        if !dislikedTags.isEmpty {
            summary += " 반대로 \(joinedDisplayText(dislikedTags, fallback: ""))은 덜 보이도록 추천에서 조심해서 반영했어요."
        }

        return summary
    }

    private func makeSafeStartingPoint(
        preferredScents: [String],
        seasonMood: String?,
        dislikedTags: [String]
    ) -> String {
        let scentText = joinedDisplayText(Array(preferredScents.prefix(2)), fallback: "선택한 취향")
        let seasonText = seasonMood.map { "\($0) 느낌으로 " } ?? ""
        let avoidText = dislikedTags.isEmpty ? "" : ", 부담스러운 향은 덜어내고"
        return "\(seasonText)\(scentText)를 중심으로\(avoidText) 시작하기 좋은 향수를 골라봤어요"
    }

    private func joinedDisplayText(_ values: [String], fallback: String) -> String {
        let cleanValues = values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanValues.isEmpty else { return fallback }
        guard cleanValues.count > 1 else { return cleanValues[0] }

        let visibleValues = Array(cleanValues.prefix(3))
        if visibleValues.count == cleanValues.count {
            return visibleValues.joined(separator: ", ")
        }

        return "\(visibleValues.joined(separator: ", ")) 외 \(cleanValues.count - visibleValues.count)개"
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
