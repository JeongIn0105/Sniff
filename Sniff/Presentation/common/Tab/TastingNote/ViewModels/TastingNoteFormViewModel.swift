//
//  TastingNoteFormViewModel.swift
//  Sniff
//
//  Created by 이정인 on 4/16/26.
//

// MARK: - 등록 로직 + Fragella 검색
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class TastingNoteFormViewModel: ObservableObject {

    // MARK: - Published (검색)

    @Published var searchText: String = ""
    @Published private(set) var searchResults: [FragellaFragrance] = []
    @Published private(set) var isSearching: Bool = false
    @Published var isSearchResultVisible: Bool = false
    @Published var searchGuideMessage: String?

    // MARK: - Published (자동 입력)

    @Published var selectedFragrance: FragellaFragrance?
    @Published var perfumeName: String = ""
    @Published var brandName: String = ""
    @Published var mainAccords: [String] = []
    @Published var concentration: String = ""

    // MARK: - Published (직접 입력)

    @Published var rating: Int = 0
    @Published var longevity: Int = 0
    @Published var selectedMoodTags: Set<String> = []
    @Published var memo: String = ""

    // MARK: - Published (상태)

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var saveSuccess: Bool = false
    @Published private(set) var savedPerfumeName: String = ""
    @Published var errorMessage: String?

    // MARK: - Public

    var allMoodTags: [String] { kMoodTagList }

    private var editingNote: TastingNote?
    var isEditMode: Bool { editingNote != nil }
    var navigationTitle: String { isEditMode ? "시향기 수정" : "시향기 등록" }

    var displayCardFragrance: FragellaFragrance? {
        guard !perfumeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        if let selectedFragrance { return selectedFragrance }
        return FragellaFragrance(
            id: editingNote?.fragranceID ?? "\(brandName)|\(perfumeName)",
            name: perfumeName,
            brand: brandName,
            koreanName: nil,
            koreanBrand: nil,
            mainAccords: mainAccords,
            concentration: concentration.isEmpty ? nil : concentration,
            imageURL: editingNote?.perfumeImageURL
        )
    }

    var canSave: Bool {
        !perfumeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        memo.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20
    }

    var memoCount: Int { memo.count }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private var latestSearchQuery: String = ""
    private var translationTask: Task<Void, Never>?
    /// selectFragrance 직후 searchText 변경이 debounce 재검색을 유발하지 않도록 차단
    private var suppressNextSearch: Bool = false

    private var uid: String? { Auth.auth().currentUser?.uid }

    private var collectionRef: CollectionReference? {
        guard let uid else { return nil }
        return Firestore.firestore()
            .collection("users").document(uid)
            .collection("tastingRecords")
    }

    // MARK: - Init

    init(editingNote: TastingNote? = nil) {
        self.editingNote = editingNote
        if let editingNote { loadEditingNote(editingNote) }
        setupSearchDebounce()
    }

    // MARK: - Load

    private func loadEditingNote(_ note: TastingNote) {
        perfumeName = note.perfumeName
        brandName = note.brandName
        // 이전 영문 태그 → 한국어 마이그레이션
        mainAccords = note.mainAccords.map {
            kLegacyTagToKorean[$0] ?? PerfumeKoreanTranslator.korean(for: $0)
        }
        concentration = note.concentration ?? ""
        rating = note.rating
        longevity = note.longevity
        // 이전 영문 무드태그 → 한국어 마이그레이션
        selectedMoodTags = Set(note.moodTags.map {
            kLegacyTagToKorean[$0] ?? $0
        })
        memo = note.memo
        searchText = note.perfumeName
        selectedFragrance = nil
    }

    // MARK: - 검색 디바운스
    // 한국어: 최소 2자 / 영문: 최소 2자로 통일

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }

                // 향수 선택 후 searchText를 프로그래밍으로 바꾼 경우 → 재검색 차단
                if self.suppressNextSearch {
                    self.suppressNextSearch = false
                    return
                }

                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

                if trimmed.isEmpty {
                    self.searchResults = []
                    self.isSearchResultVisible = false
                    self.isSearching = false
                    self.searchGuideMessage = nil
                    self.latestSearchQuery = ""
                    return
                }

                if trimmed.count < 2 {
                    self.searchResults = []
                    self.isSearchResultVisible = false
                    self.isSearching = false
                    self.searchGuideMessage = "2자 이상 입력해주세요"
                    self.latestSearchQuery = ""
                    return
                }

                self.searchGuideMessage = nil
                Task { await self.performSearch(query: trimmed) }
            }
            .store(in: &cancellables)
    }

    func searchButtonTapped() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearchResultVisible = false
            searchGuideMessage = nil
            return
        }
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearchResultVisible = false
            searchGuideMessage = "2자 이상 입력해주세요"
            return
        }
        searchGuideMessage = nil
        Task { await performSearch(query: trimmed) }
    }

    func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearchResultVisible = false
            isSearching = false
            searchGuideMessage = "2자 이상 입력해주세요"
            return
        }

        latestSearchQuery = trimmed
        let requestQuery = trimmed

        isSearching = true
        isSearchResultVisible = true
        searchGuideMessage = nil

        do {
            // 1차 시도: 입력 쿼리 그대로 검색
            var results = try await TastingNoteFragellaAPI.search(query: requestQuery)

            // 2차 시도: 한국어 포함 + 결과 없는 경우 → 영문으로 변환 후 재검색
            if results.isEmpty && PerfumeKoreanTranslator.containsKorean(requestQuery) {
                if let englishQuery = PerfumeKoreanTranslator.toEnglishQuery(requestQuery) {
                    results = try await TastingNoteFragellaAPI.search(query: englishQuery)
                }
            }

            guard latestSearchQuery == requestQuery else { return }

            // 향수명 음역 번역 (결과 표시 전 완료 → 처음부터 한국어로 표시)
            translationTask?.cancel()
            let needsTranslation = results.filter { $0.koreanName == nil }
            if !needsTranslation.isEmpty {
                let englishNames = needsTranslation.map { $0.name }
                if let translations = try? await PerfumeNameTranslationService.translate(names: englishNames),
                   latestSearchQuery == requestQuery {
                    results = results.map { fragrance in
                        guard let korean = translations[fragrance.name] else { return fragrance }
                        return FragellaFragrance(
                            id: fragrance.id,
                            name: fragrance.name,
                            brand: fragrance.brand,
                            koreanName: korean,
                            koreanBrand: fragrance.koreanBrand,
                            mainAccords: fragrance.mainAccords,
                            concentration: fragrance.concentration,
                            imageURL: fragrance.imageURL
                        )
                    }
                }
            }

            guard latestSearchQuery == requestQuery else { return }
            searchResults = results
            isSearching = false
        } catch {
            guard latestSearchQuery == requestQuery else { return }
            searchResults = []
            isSearching = false
            isSearchResultVisible = false
            // 404 = 결과 없음 (에러 메시지 숨김)
            if let apiErr = error as? FragellaAPIError,
               case .noResults = apiErr {
                searchGuideMessage = nil
            } else {
                searchGuideMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 향수 선택

    func selectFragrance(_ fragrance: FragellaFragrance) {
        selectedFragrance = fragrance
        // displayName(한국어 우선), displayBrand(한국어 우선) 저장
        perfumeName = fragrance.displayName
        brandName = fragrance.displayBrand
        // mainAccords는 이미 parseFragrances에서 한국어 변환됨
        mainAccords = fragrance.mainAccords
        concentration = fragrance.concentration ?? ""

        suppressNextSearch = true
        searchText = fragrance.displayName
        isSearchResultVisible = false
        searchResults = []
        searchGuideMessage = nil
        latestSearchQuery = fragrance.displayName
    }

    func clearSelectedFragrance() {
        let autoInsertedTags = Set(mainAccords.filter { allMoodTags.contains($0) })
        selectedFragrance = nil
        perfumeName = ""
        brandName = ""
        mainAccords = []
        concentration = ""
        searchText = ""
        isSearchResultVisible = false
        searchResults = []
        searchGuideMessage = nil
        latestSearchQuery = ""
        selectedMoodTags.subtract(autoInsertedTags)
    }

    // MARK: - 태그 토글

    func toggleMoodTag(_ tag: String) {
        if selectedMoodTags.contains(tag) {
            selectedMoodTags.remove(tag)
        } else {
            selectedMoodTags.insert(tag)
        }
    }

    // MARK: - 초기화

    func reset() {
        errorMessage = nil
        saveSuccess = false
        searchResults = []
        isSearchResultVisible = false
        selectedFragrance = nil
        searchGuideMessage = nil
        latestSearchQuery = ""

        if let editingNote {
            loadEditingNote(editingNote)
        } else {
            searchText = ""
            perfumeName = ""
            brandName = ""
            mainAccords = []
            concentration = ""
            rating = 0
            longevity = 0
            selectedMoodTags = []
            memo = ""
        }
    }

    // MARK: - 저장

    func save() async {
        guard canSave, let ref = collectionRef else { return }
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
            longevity: longevity,
            moodTags: orderedMoodTags(from: selectedMoodTags),
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            perfumeImageURL: selectedFragrance?.imageURL ?? editingNote?.perfumeImageURL,
            fragranceID: selectedFragrance?.id ?? editingNote?.fragranceID,
            createdAt: editingNote?.createdAt ?? now,
            updatedAt: now
        )

        do {
            if let id = editingNote?.id {
                try ref.document(id).setData(from: note)
            } else {
                try ref.addDocument(from: note)
            }
            savedPerfumeName = perfumeName
            saveSuccess = true
        } catch {
            errorMessage = "저장 중 오류가 발생했어요"
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
}

// MARK: - Fragella API (한국어 번역 포함)

private enum TastingNoteFragellaAPI {

    static func search(query: String) async throws -> [FragellaFragrance] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { throw FragellaAPIError.minimumSearchLength }
        guard FragellaConfig.hasValidAPIKey else { throw FragellaAPIError.missingAPIKey }

        var components = URLComponents(string: "https://api.fragella.com/api/v1/fragrances")
        components?.queryItems = [
            URLQueryItem(name: "search", value: trimmed),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = components?.url else { throw FragellaAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(FragellaConfig.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw FragellaAPIError.invalidResponse }

        // 404 = 결과 없음 (Fragella API 동작), 에러로 처리하지 않음
        if http.statusCode == 404 {
            return []
        }

        guard 200..<300 ~= http.statusCode else {
            let msg = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
            if http.statusCode == 400 && msg.localizedCaseInsensitiveContains("at least") {
                throw FragellaAPIError.minimumSearchLength
            }
            throw FragellaAPIError.serverError(statusCode: http.statusCode, message: msg)
        }

        // Primary 이미지가 있는 결과만 포함 (fallback 이미지는 실제 없는 경우가 많음)
        return try parseFragrances(from: data).filter { $0.imageURL != nil }
    }

    // MARK: - 파싱 (accord 한국어 변환 포함)

    private static func parseFragrances(from data: Data) throws -> [FragellaFragrance] {
        let jsonObject = try JSONSerialization.jsonObject(with: data)

        let items: [[String: Any]]
        if let array = jsonObject as? [[String: Any]] {
            items = array
        } else if let dict = jsonObject as? [String: Any] {
            items = (dict["data"] ?? dict["results"] ?? dict["items"] ?? dict["fragrances"])
                .flatMap { $0 as? [[String: Any]] } ?? []
        } else {
            throw FragellaAPIError.decodingFailed
        }

        return items.compactMap { item in
            // 영문명 (필수)
            guard let name  = strValue(["Name", "name"], item)?.nilIfBlank,
                  let brand = strValue(["Brand", "brand"], item)?.nilIfBlank else { return nil }

            // 한국어 이름 (API 제공 시)
            let koreanName  = strValue(["koreanName", "korean_name", "nameKo", "name_ko",
                                        "KoreanName", "Korean Name"], item)?.nilIfBlank
            let koreanBrand = strValue(["koreanBrand", "korean_brand", "brandKo", "brand_ko",
                                        "KoreanBrand", "Korean Brand"], item)?.nilIfBlank

            let fragranceID = strValue(["id", "ID", "fragranceId", "fragranceID", "Fragrance ID"], item)?.nilIfBlank
                ?? "\(brand)|\(name)"

            // 영문 accord → 한국어 변환
            let rawAccords  = arrValue(["Main Accords", "mainAccords", "main_accords"], item)
            let mainAccords = PerfumeKoreanTranslator.koreanAccords(for: rawAccords)

            let concentration = strValue(["OilType", "oilType", "concentration"], item)?.nilIfBlank

            // 이미지 URL — primary 이미지만 사용 (fallback은 실제 이미지 없는 경우가 많아 제외)
            let imageURL = strValue(["Image URL", "imageURL", "imageUrl", "image_url"], item)?.nilIfBlank

            return FragellaFragrance(
                id: fragranceID,
                name: name,
                brand: brand,
                koreanName: koreanName,
                koreanBrand: koreanBrand,
                mainAccords: mainAccords,
                concentration: concentration,
                imageURL: imageURL
            )
        }
    }

    // MARK: - 파싱 헬퍼

    private static func strValue(_ keys: [String], _ dict: [String: Any]) -> String? {
        for key in keys {
            if let v = dict[key] as? String { return v }
            if let v = dict[key] as? NSNumber { return v.stringValue }
        }
        return nil
    }

    private static func arrValue(_ keys: [String], _ dict: [String: Any]) -> [String] {
        for key in keys {
            if let arr = dict[key] as? [String] { return arr }
            if let arr = dict[key] as? [Any] {
                return arr.compactMap {
                    ($0 as? String) ?? ($0 as? NSNumber)?.stringValue
                }
            }
            if let str = dict[key] as? String {
                let parts = str.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !parts.isEmpty { return parts }
            }
        }
        return []
    }
}

// MARK: - Fragella Error

private enum FragellaAPIError: LocalizedError {
    case missingAPIKey, minimumSearchLength, invalidURL
    case invalidResponse, decodingFailed, noResults
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:         return "Fragella API 키를 먼저 설정해주세요"
        case .minimumSearchLength:   return "3자 이상 입력해주세요"
        case .invalidURL:            return "요청 URL 생성에 실패했어요"
        case .invalidResponse:       return "응답을 확인할 수 없어요"
        case .decodingFailed:        return "응답 해석에 실패했어요"
        case .noResults:             return nil
        case let .serverError(code, msg): return "검색 실패 (\(code))\n\(msg)"
        }
    }
}

// MARK: - Config

private enum FragellaConfig {
    static let apiKey = "0e4d3ff3231b3243fa544f797311c0df9175c3ce946c3df588365a70f76961e3"
    static var hasValidAPIKey: Bool {
        let t = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && t != "YOUR_FRAGELLA_API_KEY"
    }
}

// MARK: - Helpers

private extension String {
    var nilIfBlank: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
