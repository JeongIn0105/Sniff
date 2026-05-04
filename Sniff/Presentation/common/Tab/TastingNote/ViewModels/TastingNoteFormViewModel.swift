//
//  TastingNoteFormViewModel.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 등록 로직
import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestore

struct TastingPerfumeMatchCandidate: Identifiable, Equatable {
    let brandName: String
    let perfumeName: String?
    let imageURL: String?

    var id: String {
        "\(brandName.lowercased())|\((perfumeName ?? "").lowercased())"
    }

    var title: String {
        if let perfumeName, !perfumeName.isEmpty {
            return PerfumePresentationSupport.displayPerfumeName(perfumeName)
        }
        return PerfumePresentationSupport.displayBrand(brandName)
    }

    var subtitle: String {
        if perfumeName == nil {
            let displayBrand = PerfumePresentationSupport.displayBrand(brandName)
            return displayBrand == brandName ? "브랜드 후보" : "\(brandName) 브랜드 후보"
        }
        return PerfumePresentationSupport.displayBrand(brandName)
    }
}

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
    @Published var memo: String = ""

    // MARK: - Published (상태)

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var saveSuccess: Bool = false
    @Published private(set) var savedPerfumeName: String = ""
    @Published private(set) var perfumeMatchCandidates: [TastingPerfumeMatchCandidate] = []
    @Published var errorMessage: String?

    // MARK: - Public

    var allMoodTags: [String] { kMoodTagList }
    var allUsageContexts: [String] { TastingUsageContext.allCases.map(\.displayName) }

    private var editingNote: TastingNote?
    private let localRepository: LocalTastingNoteRepository
    private let localPerfumeSearchService: LocalPerfumeSearchService
    private let isOwnedPerfumeContext: Bool
    var isEditMode: Bool { editingNote != nil }
    var navigationTitle: String { isEditMode ? AppStrings.TastingNoteUI.List.edit : AppStrings.TastingNoteUI.List.add }
    var shouldShowUsageContext: Bool { isOwnedPerfumeContext || usageContext != nil }

    var canSave: Bool {
        isPerfumeNameValid &&
        isBrandNameValid &&
        isRatingValid &&
        isMoodTagsValid &&
        isMemoValid
    }

    var saveRequirementMessage: String? {
        if !isPerfumeNameValid || !isBrandNameValid {
            return "향수 명과 브랜드를 입력해주세요"
        }
        if !isRatingValid {
            return "향 선호도 점수를 선택해주세요"
        }
        if !isMoodTagsValid {
            return "분위기&이미지를 1개 이상 선택해주세요"
        }
        if !isMemoValid {
            return "시향 메모를 10자 이상 입력해주세요"
        }
        return nil
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

    var isMemoValid: Bool {
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedMemo.count >= Self.minMemoCount,
              trimmedMemo.count <= Self.maxMemoCount else {
            return false
        }

        var containsLetter = false

        for scalar in trimmedMemo.unicodeScalars {
            if Self.isKoreanScalar(scalar) || Self.isEnglishScalar(scalar) {
                containsLetter = true
                continue
            }

            if Self.isNumberScalar(scalar) ||
                Self.allowedWhitespaceScalars.contains(scalar) ||
                Self.allowedPunctuationScalars.contains(scalar) {
                continue
            }

            return false
        }

        return containsLetter
    }

    // MARK: - Private

    private static let minMemoCount = 10
    private static let maxMemoCount = 2000
    private static let allowedWhitespaceScalars = CharacterSet.whitespacesAndNewlines
    private static let allowedPunctuationScalars = CharacterSet(charactersIn: ".,!?~")
    private static let manualBrandCorrections: [String: String] = [
        "조말롱": "Jo Malone London",
        "조말론": "Jo Malone London",
        "딥티그": "Diptyque",
        "딥티크": "Diptyque",
        "그리드": "Creed",
        "크리드": "Creed"
    ]

    private var perfumeImageURL: String?
    private var isApplyingMatchCandidate = false

    // MARK: - Init

    init(
        localRepository: LocalTastingNoteRepository,
        localPerfumeSearchService: LocalPerfumeSearchService = LocalPerfumeSearchService(),
        editingNote: TastingNote? = nil,
        initialPerfume: Perfume? = nil,
        isOwnedPerfumeContext: Bool = false
    ) {
        self.localRepository = localRepository
        self.localPerfumeSearchService = localPerfumeSearchService
        self.editingNote = editingNote
        self.isOwnedPerfumeContext = isOwnedPerfumeContext
        self.localPerfumeSearchService.buildIndex(includesUserData: false)
        if let editingNote {
            loadEditingNote(editingNote)
        } else if let initialPerfume {
            preloadPerfume(initialPerfume)
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

    func refreshPerfumeMatchCandidates() {
        guard !isApplyingMatchCandidate else { return }

        let perfumeQuery = perfumeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let brandQuery = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !perfumeQuery.isEmpty || !brandQuery.isEmpty else {
            perfumeMatchCandidates = []
            return
        }

        var candidates: [TastingPerfumeMatchCandidate] = []
        let queries = [
            [brandQuery, perfumeQuery].filter { !$0.isEmpty }.joined(separator: " "),
            perfumeQuery,
            brandQuery
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }

        for query in queries {
            let suggestions = localPerfumeSearchService.suggestions(for: query)
            candidates.append(contentsOf: suggestions.compactMap(makeCandidate(from:)))
        }
        candidates.append(contentsOf: brandCorrectionCandidates(for: brandQuery))
        if perfumeQuery.count >= 2, brandQuery.isEmpty {
            candidates.append(contentsOf: brandCorrectionCandidates(for: perfumeQuery))
        }

        perfumeMatchCandidates = uniqueCandidates(candidates)
            .filter { !isSameCurrentInput($0) }
            .prefix(3)
            .map { $0 }
    }

    func applyMatchCandidate(_ candidate: TastingPerfumeMatchCandidate) {
        isApplyingMatchCandidate = true
        brandName = PerfumePresentationSupport.displayBrand(candidate.brandName)
        if let perfumeName = candidate.perfumeName {
            self.perfumeName = PerfumePresentationSupport.displayPerfumeName(perfumeName)
        }
        perfumeImageURL = candidate.imageURL
        perfumeMatchCandidates = []
        isApplyingMatchCandidate = false
    }

    // MARK: - 초기화

    func reset() {
        errorMessage = nil
        saveSuccess = false

        if let editingNote {
            loadEditingNote(editingNote)
        } else {
            perfumeName = ""
            brandName = ""
            mainAccords = []
            concentration = ""
            perfumeImageURL = nil
            perfumeMatchCandidates = []
            rating = 0
            selectedMoodTags = []
            revisitDesire = nil
            usageContext = nil
            memo = ""
        }
    }

    // MARK: - 저장

    func save() async {
        guard !isSaving else { return }
        guard canSave else {
            errorMessage = saveRequirementMessage
            return
        }
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
        tags.sorted {
            let li = allMoodTags.firstIndex(of: $0) ?? Int.max
            let ri = allMoodTags.firstIndex(of: $1) ?? Int.max
            return li < ri
        }
    }

    private func makeCandidate(from suggestion: SuggestionItem) -> TastingPerfumeMatchCandidate? {
        switch suggestion {
        case let .brand(name, imageUrl):
            return TastingPerfumeMatchCandidate(
                brandName: name,
                perfumeName: nil,
                imageURL: imageUrl
            )
        case let .perfume(name, brand, imageUrl):
            return TastingPerfumeMatchCandidate(
                brandName: brand,
                perfumeName: name,
                imageURL: imageUrl
            )
        }
    }

    private func brandCorrectionCandidates(for query: String) -> [TastingPerfumeMatchCandidate] {
        let normalizedQuery = normalizeForCandidateMatch(query)
        guard normalizedQuery.count >= 2 else { return [] }

        var candidates: [TastingPerfumeMatchCandidate] = []
        if let corrected = Self.manualBrandCorrections[normalizedQuery] {
            candidates.append(TastingPerfumeMatchCandidate(brandName: corrected, perfumeName: nil, imageURL: nil))
        }

        let dictionaryCandidates = PerfumeKoreanTranslator.koreanToBrand.map { pair in
            (korean: pair.key, english: pair.value, score: brandCandidateScore(query: normalizedQuery, candidate: pair.key))
        }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.korean.localizedCaseInsensitiveCompare(rhs.korean) == .orderedAscending
            }
            .prefix(2)
            .map { TastingPerfumeMatchCandidate(brandName: $0.english, perfumeName: nil, imageURL: nil) }

        candidates.append(contentsOf: dictionaryCandidates)
        return candidates
    }

    private func brandCandidateScore(query: String, candidate: String) -> Int {
        let normalizedCandidate = normalizeForCandidateMatch(candidate)
        if normalizedCandidate == query { return 1_000 }
        if normalizedCandidate.contains(query) || query.contains(normalizedCandidate) { return 800 }
        if isNearTypo(normalizedCandidate, query) { return 650 }
        return 0
    }

    private func uniqueCandidates(_ candidates: [TastingPerfumeMatchCandidate]) -> [TastingPerfumeMatchCandidate] {
        var seen = Set<String>()
        return candidates.filter { seen.insert($0.id).inserted }
    }

    private func isSameCurrentInput(_ candidate: TastingPerfumeMatchCandidate) -> Bool {
        let currentBrand = normalizeForCandidateMatch(brandName)
        let candidateBrand = normalizeForCandidateMatch(PerfumePresentationSupport.displayBrand(candidate.brandName))
        let currentPerfume = normalizeForCandidateMatch(perfumeName)
        let candidatePerfume = normalizeForCandidateMatch(
            candidate.perfumeName.map(PerfumePresentationSupport.displayPerfumeName) ?? ""
        )

        if candidate.perfumeName == nil {
            return !currentBrand.isEmpty && currentBrand == candidateBrand
        }
        return !currentBrand.isEmpty
            && !currentPerfume.isEmpty
            && currentBrand == candidateBrand
            && currentPerfume == candidatePerfume
    }

    private func normalizeForCandidateMatch(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private func isNearTypo(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs.count >= 2, rhs.count >= 2 else { return false }
        guard abs(lhs.count - rhs.count) <= 1 else { return false }
        return editDistance(lhs, rhs, maxDistance: 1) <= 1
    }

    private func editDistance(_ lhs: String, _ rhs: String, maxDistance: Int) -> Int {
        let lhs = Array(lhs)
        let rhs = Array(rhs)
        if abs(lhs.count - rhs.count) > maxDistance { return maxDistance + 1 }
        if lhs.isEmpty { return rhs.count }
        if rhs.isEmpty { return lhs.count }

        var previous = Array(0...rhs.count)
        for i in 1...lhs.count {
            var current = [i] + Array(repeating: 0, count: rhs.count)
            var rowMinimum = current[0]
            for j in 1...rhs.count {
                let cost = lhs[i - 1] == rhs[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
                rowMinimum = min(rowMinimum, current[j])
            }
            if rowMinimum > maxDistance { return maxDistance + 1 }
            previous = current
        }
        return previous[rhs.count]
    }

    private static func isKoreanScalar(_ scalar: UnicodeScalar) -> Bool {
        (0xAC00...0xD7A3).contains(Int(scalar.value))
    }

    private static func isEnglishScalar(_ scalar: UnicodeScalar) -> Bool {
        (0x41...0x5A).contains(Int(scalar.value)) ||
        (0x61...0x7A).contains(Int(scalar.value))
    }

    private static func isNumberScalar(_ scalar: UnicodeScalar) -> Bool {
        (0x30...0x39).contains(Int(scalar.value))
    }
}
