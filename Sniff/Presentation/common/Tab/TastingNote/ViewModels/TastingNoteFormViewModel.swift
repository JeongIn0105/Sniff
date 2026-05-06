//
//  TastingNoteFormViewModel.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 등록 로직
import Foundation
import Combine

@MainActor
final class TastingNoteFormViewModel: ObservableObject {

    // MARK: - Published (향수 정보)

    @Published var perfumeName: String = ""
    @Published var brandName: String = ""
    @Published var mainAccords: [String] = []
    @Published var concentration: String = ""

    // MARK: - Published (직접 입력)

    @Published var rating: Int = 0
    @Published var selectedMoodTags: Set<String> = []
    @Published var revisitDesire: String? = nil   // 다시 쓰고 싶은지 (단일 선택, 선택 안 해도 저장 가능)
    @Published var usageContext: String? = nil
    @Published var longevityExperience: String? = nil
    @Published var sillageExperience: String? = nil
    @Published var drydownChange: String? = nil
    @Published var skinChemistry: String? = nil
    @Published var selectedWearSituations: Set<String> = []
    @Published var selectedWeatherContexts: Set<String> = []
    @Published var selectedApplicationAreas: Set<String> = []
    @Published var memo: String = ""
    @Published private(set) var ownedPerfumes: [CollectedPerfume] = []
    @Published private(set) var selectedOwnedPerfumeID: String?
    @Published private(set) var isLoadingOwnedPerfumes: Bool = false

    // MARK: - Published (상태)

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var saveSuccess: Bool = false
    @Published private(set) var savedPerfumeName: String = ""
    @Published var errorMessage: String?

    // MARK: - Public

    var allMoodTags: [String] { kMoodTagList }
    var allUsageContexts: [String] { TastingUsageContext.allCases.map(\.displayName) }
    var allLongevityExperiences: [String] { TastingLongevityExperience.allCases.map(\.displayName) }
    var allSillageExperiences: [String] { TastingSillageExperience.allCases.map(\.displayName) }
    var allDrydownChanges: [String] { TastingDrydownChange.allCases.map(\.displayName) }
    var allSkinChemistries: [String] { TastingSkinChemistry.allCases.map(\.displayName) }
    var allWearSituations: [String] { TastingWearSituation.allCases.map(\.displayName) }
    var allWeatherContexts: [String] { TastingWeatherContext.allCases.map(\.displayName) }
    var allApplicationAreas: [String] { TastingApplicationArea.allCases.map(\.displayName) }

    private var editingNote: TastingNote?
    private let localRepository: LocalTastingNoteRepository
    private let collectionRepository: CollectionRepositoryType?
    private let initialPerfume: Perfume?
    private let isOwnedPerfumeContext: Bool
    var isEditMode: Bool { editingNote != nil }
    var usesOwnedPerfumeWritingMode: Bool {
        isOwnedPerfumeContext
        || usageContext != nil
        || longevityExperience != nil
        || sillageExperience != nil
        || drydownChange != nil
        || skinChemistry != nil
        || !selectedWearSituations.isEmpty
        || !selectedWeatherContexts.isEmpty
        || !selectedApplicationAreas.isEmpty
    }
    var navigationTitle: String {
        if usesOwnedPerfumeWritingMode {
            return isEditMode ? "사용 기록 수정" : "사용 기록 작성"
        }
        return isEditMode ? AppStrings.TastingNoteUI.List.edit : AppStrings.TastingNoteUI.List.add
    }
    var shouldShowUsageContext: Bool { isOwnedPerfumeContext || usageContext != nil }
    var isPerfumeIdentityEditable: Bool { !usesOwnedPerfumeWritingMode }
    var perfumeSectionTitle: String { usesOwnedPerfumeWritingMode ? "보유 향수" : "시향 향수" }
    var perfumeNameFieldTitle: String { usesOwnedPerfumeWritingMode ? "향수" : "향수 명" }
    var perfumeNamePlaceholder: String {
        usesOwnedPerfumeWritingMode ? "보유 향수 정보가 표시돼요" : "향수 명을 입력하세요"
    }
    var shouldShowOwnedPerfumePicker: Bool {
        isOwnedPerfumeContext && !isEditMode && initialPerfume == nil
    }
    var ownedPerfumePickerHint: String {
        ownedPerfumes.isEmpty
            ? "등록된 보유 향수가 없어요"
            : "사용 기록을 남길 보유 향수를 선택해주세요"
    }
    var brandFieldTitle: String { "브랜드" }
    var brandPlaceholder: String {
        usesOwnedPerfumeWritingMode ? "보유 브랜드 정보가 표시돼요" : "향수 브랜드를 입력하세요"
    }
    var ratingSectionTitle: String { usesOwnedPerfumeWritingMode ? "사용 만족도" : "향 선호도" }
    var ratingHintText: String {
        usesOwnedPerfumeWritingMode
            ? "*오늘 사용감과 만족도를 터치하여 입력해주세요"
            : "*향수의 선호도 점수를 터치하여 입력해주세요"
    }
    var moodSectionTitle: String { usesOwnedPerfumeWritingMode ? "오늘 느낀 분위기" : "분위기&이미지" }
    var usageContextTitle: String { "사용 맥락" }
    var memoSectionTitle: String { usesOwnedPerfumeWritingMode ? "사용 메모" : "시향 메모" }
    var memoPlaceholder: String {
        usesOwnedPerfumeWritingMode
            ? "오늘 뿌렸을 때의 잔향, 지속력, 주변 반응, 다시 쓰고 싶은 상황을 기록해주세요"
            : AppStrings.TastingNoteFormUI.memoPlaceholder
    }
    var memoHelperText: String {
        usesOwnedPerfumeWritingMode
            ? "선택 입력 · 실제 사용감은 추천 취향에 더 강하게 반영돼요"
            : "선택 입력 · 최대 \(maxMemoCount)자까지 작성할 수 있어요"
    }
    var saveButtonTitle: String { usesOwnedPerfumeWritingMode ? "기록 완료" : AppStrings.TastingNoteFormUI.save }

    var canSave: Bool {
        isPerfumeNameValid &&
        isBrandNameValid &&
        isRatingValid &&
        isMoodTagsValid
    }

    var memoCount: Int { memo.count }
    var maxMemoCount: Int { Self.maxMemoCount }

    var isPerfumeNameValid: Bool {
        !perfumeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isBrandNameValid: Bool {
        !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isRatingValid: Bool {
        (1...5).contains(rating)
    }

    var isMoodTagsValid: Bool {
        !selectedMoodTags.isEmpty
    }

    // MARK: - Private

    private static let maxMemoCount = 2000

    private var perfumeImageURL: String?

    // MARK: - Init

    init(
        localRepository: LocalTastingNoteRepository,
        collectionRepository: CollectionRepositoryType? = nil,
        editingNote: TastingNote? = nil,
        initialPerfume: Perfume? = nil,
        isOwnedPerfumeContext: Bool = false
    ) {
        self.localRepository = localRepository
        self.collectionRepository = collectionRepository
        self.editingNote = editingNote
        self.initialPerfume = initialPerfume
        self.isOwnedPerfumeContext = isOwnedPerfumeContext
        if let editingNote {
            loadEditingNote(editingNote)
        } else if let initialPerfume {
            preloadPerfume(initialPerfume)
            if isOwnedPerfumeContext {
                usageContext = TastingUsageContext.today.displayName
            }
        } else if isOwnedPerfumeContext {
            usageContext = TastingUsageContext.today.displayName
            Task { await loadOwnedPerfumesForSelection() }
        }
    }

    // MARK: - Load

    private func loadEditingNote(_ note: TastingNote) {
        perfumeName = note.perfumeName
        brandName = note.brandName
        mainAccords = PerfumePresentationSupport.displayFamilies(note.mainAccords)
        concentration = note.concentration ?? ""
        rating = note.rating
        // 이전 영문 무드태그 → 한국어 마이그레이션
        selectedMoodTags = Set(note.moodTags.map {
            kLegacyMoodTagToKorean[$0] ?? $0
        })
        revisitDesire = note.revisitDesire
        usageContext = note.usageContext
        longevityExperience = note.longevityExperience
        sillageExperience = note.sillageExperience
        drydownChange = note.drydownChange
        skinChemistry = note.skinChemistry
        selectedWearSituations = Set(note.wearSituations)
        selectedWeatherContexts = Set(note.weatherContexts)
        selectedApplicationAreas = Set(note.applicationAreas)
        memo = note.memo
        perfumeImageURL = note.perfumeImageURL
    }

    private func preloadPerfume(_ perfume: Perfume) {
        perfumeName = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        brandName = PerfumePresentationSupport.displayBrand(perfume.brand)
        mainAccords = PerfumeKoreanTranslator.koreanAccords(for: perfume.mainAccords)
        concentration = perfume.concentration ?? ""
        perfumeImageURL = perfume.imageUrl
    }

    func loadOwnedPerfumesForSelection() async {
        guard shouldShowOwnedPerfumePicker, initialPerfume == nil else { return }
        guard let collectionRepository else { return }
        isLoadingOwnedPerfumes = true
        defer { isLoadingOwnedPerfumes = false }

        do {
            let perfumes = try await collectionRepository.fetchCollection().async()
            ownedPerfumes = perfumes.sorted { lhs, rhs in
                let lhsName = PerfumePresentationSupport.displayPerfumeName(lhs.name)
                let rhsName = PerfumePresentationSupport.displayPerfumeName(rhs.name)
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
            if selectedOwnedPerfumeID == nil, ownedPerfumes.count == 1, let perfume = ownedPerfumes.first {
                selectOwnedPerfume(perfume)
            }
        } catch {
            errorMessage = "보유 향수 목록을 불러오지 못했어요."
        }
    }

    func selectOwnedPerfume(_ perfume: CollectedPerfume) {
        selectedOwnedPerfumeID = perfume.id
        preloadPerfume(perfume.toPerfume())
        if usageContext == nil {
            usageContext = TastingUsageContext.today.displayName
        }
    }

    // MARK: - 태그 토글

    func toggleMoodTag(_ tag: String) {
        if selectedMoodTags.contains(tag) {
            selectedMoodTags.remove(tag)
        } else {
            selectedMoodTags.insert(tag)
        }
    }

    /// 다시 쓰고 싶은지 단일 선택 — 이미 선택된 태그를 탭하면 선택 해제
    func toggleRevisitDesire(_ tag: String) {
        revisitDesire = (revisitDesire == tag) ? nil : tag
    }

    func toggleUsageContext(_ context: String) {
        usageContext = (usageContext == context) ? nil : context
    }

    func toggleLongevityExperience(_ value: String) {
        longevityExperience = (longevityExperience == value) ? nil : value
    }

    func toggleSillageExperience(_ value: String) {
        sillageExperience = (sillageExperience == value) ? nil : value
    }

    func toggleDrydownChange(_ value: String) {
        drydownChange = (drydownChange == value) ? nil : value
    }

    func toggleSkinChemistry(_ value: String) {
        skinChemistry = (skinChemistry == value) ? nil : value
    }

    func toggleWearSituation(_ value: String) {
        toggle(value, in: &selectedWearSituations)
    }

    func toggleWeatherContext(_ value: String) {
        toggle(value, in: &selectedWeatherContexts)
    }

    func toggleApplicationArea(_ value: String) {
        toggle(value, in: &selectedApplicationAreas)
    }

    // MARK: - 초기화

    func reset() {
        errorMessage = nil
        saveSuccess = false

        if let editingNote {
            loadEditingNote(editingNote)
        } else {
            if let initialPerfume {
                preloadPerfume(initialPerfume)
            } else if let selectedOwnedPerfumeID,
                      let selectedPerfume = ownedPerfumes.first(where: { $0.id == selectedOwnedPerfumeID }) {
                selectOwnedPerfume(selectedPerfume)
            } else {
                perfumeName = ""
                brandName = ""
                mainAccords = []
                concentration = ""
                perfumeImageURL = nil
            }
            rating = 0
            selectedMoodTags = []
            revisitDesire = nil
            usageContext = isOwnedPerfumeContext ? TastingUsageContext.today.displayName : nil
            longevityExperience = nil
            sillageExperience = nil
            drydownChange = nil
            skinChemistry = nil
            selectedWearSituations = []
            selectedWeatherContexts = []
            selectedApplicationAreas = []
            memo = ""
        }
    }

    // MARK: - 저장

    func save() async {
        guard !isSaving else { return }
        guard canSave else { return }
        isSaving = true
        errorMessage = nil

        let now = Date()
        let note = TastingNote(
            id: editingNote?.id,
            perfumeName: perfumeName,
            brandName: brandName,
            mainAccords: mainAccords,
            concentration: concentration.isEmpty ? nil : concentration,
            rating: rating,
            moodTags: orderedMoodTags(from: selectedMoodTags),
            revisitDesire: revisitDesire,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            perfumeImageURL: perfumeImageURL,
            usageContext: shouldShowUsageContext ? usageContext : nil,
            longevityExperience: usesOwnedPerfumeWritingMode ? longevityExperience : nil,
            sillageExperience: usesOwnedPerfumeWritingMode ? sillageExperience : nil,
            drydownChange: usesOwnedPerfumeWritingMode ? drydownChange : nil,
            skinChemistry: usesOwnedPerfumeWritingMode ? skinChemistry : nil,
            wearSituations: usesOwnedPerfumeWritingMode ? orderedValues(selectedWearSituations, in: allWearSituations) : [],
            weatherContexts: usesOwnedPerfumeWritingMode ? orderedValues(selectedWeatherContexts, in: allWeatherContexts) : [],
            applicationAreas: usesOwnedPerfumeWritingMode ? orderedValues(selectedApplicationAreas, in: allApplicationAreas) : [],
            createdAt: editingNote?.createdAt ?? now,
            updatedAt: now
        )

        do {
            let savedNote = try await localRepository.save(note)
            savedPerfumeName = savedNote.perfumeName
            saveSuccess = true
        } catch {
            errorMessage = AppStrings.ViewModelMessages.TastingNoteForm.saveFailed
        }
        isSaving = false
    }

    private func orderedMoodTags(from tags: Set<String>) -> [String] {
        orderedValues(tags, in: allMoodTags)
    }

    private func orderedValues(_ values: Set<String>, in source: [String]) -> [String] {
        values.sorted {
            let li = source.firstIndex(of: $0) ?? Int.max
            let ri = source.firstIndex(of: $1) ?? Int.max
            return li < ri
        }
    }

    private func toggle(_ value: String, in set: inout Set<String>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }

}
