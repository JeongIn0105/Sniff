//
//  ViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

    // SearchViewModel.swift
    // 킁킁(Sniff) - 검색 ViewModel (RxSwift + MVVM)

import Foundation
import RxSwift
import RxRelay

final class SearchViewModel {

        // MARK: - Input (View → ViewModel)
    struct Input {
        let beginEditing: Observable<Void>
        let searchText: Observable<String>
        let searchTrigger: Observable<String>    // 검색 실행 (키보드 Return / 연관어 탭)
        let clearTrigger: Observable<Void>       // X 버튼
        let recentSearchTap: Observable<String>  // 최근 검색어 탭
        let suggestionTap: Observable<SuggestionItem> // 연관 검색어 탭
        let deleteRecentSearch: Observable<String>    // 최근 검색어 개별 삭제
        let clearAllRecentSearches: Observable<Void>  // 모두 지우기
        let filterChanged: Observable<SearchFilter>   // 필터 변경
        let sortChanged: Observable<SortOption>       // 정렬 변경
    }

        // MARK: - Output (ViewModel → View)
    struct Output {
        let state: Observable<SearchState>
        let recentSearches: Observable<[RecentSearch]>
        let suggestions: Observable<[SuggestionItem]>
        let brandResults: Observable<[Perfume]>
        let perfumeResults: Observable<[Perfume]>
        let filteredPerfumeResults: Observable<[Perfume]>
        let isLoading: Observable<Bool>
        let activeFilter: Observable<SearchFilter>
        let currentSort: Observable<SortOption>
        let resultCount: Observable<Int>
    }

        // MARK: - Dependencies
    private let perfumeCatalogRepository: PerfumeCatalogRepositoryType
    private let recentSearchStore: RecentSearchStoreType
    private let localSearch: LocalPerfumeSearchService
    private let disposeBag = DisposeBag()
    private let initialState: SearchState

        // MARK: - State
    private let stateRelay: BehaviorRelay<SearchState>
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let brandResultsRelay = BehaviorRelay<[Perfume]>(value: [])
    private let perfumeResultsRelay = BehaviorRelay<[Perfume]>(value: [])
    private let suggestionsRelay = BehaviorRelay<[SuggestionItem]>(value: [])
    private let activeFilterRelay = BehaviorRelay<SearchFilter>(value: SearchFilter())
    private let currentSortRelay = BehaviorRelay<SortOption>(value: .recommended)

    // MARK: - 자동저장 상태
    /// View가 구독할 수 있는 자동저장 활성화 여부 Observable
    var autoSaveEnabled: Observable<Bool> {
        autoSaveEnabledRelay.asObservable()
    }
    private let autoSaveEnabledRelay: BehaviorRelay<Bool>

        // MARK: - Init
    init(
        perfumeCatalogRepository: PerfumeCatalogRepositoryType,
        recentSearchStore: RecentSearchStoreType,
        localSearch: LocalPerfumeSearchService = LocalPerfumeSearchService(),
        initialState: SearchState = .landing
    ) {
        self.perfumeCatalogRepository = perfumeCatalogRepository
        self.recentSearchStore = recentSearchStore
        self.localSearch = localSearch
        self.initialState = initialState
        self.stateRelay = BehaviorRelay<SearchState>(value: initialState)
        self.autoSaveEnabledRelay = BehaviorRelay<Bool>(value: recentSearchStore.isAutoSaveEnabled)
        // 로컬 검색 인덱스를 백그라운드에서 미리 구축 (API 호출 없음)
        localSearch.buildIndex()
    }

    // MARK: - 자동저장 토글

    /// 자동저장 켜기/끄기 — View에서 사용자 액션 후 호출
    func setAutoSaveEnabled(_ enabled: Bool) {
        recentSearchStore.setAutoSaveEnabled(enabled)
        autoSaveEnabledRelay.accept(enabled)
    }

        // MARK: - Transform
    func transform(input: Input) -> Output {

            // 텍스트 입력 → 상태 전환 + 로컬 자동완성
        input.searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                guard let self else { return }
                if case let .result(query) = self.stateRelay.value,
                   text == query.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return
                }
                if text.isEmpty {
                    if case .suggesting = self.stateRelay.value {
                        self.stateRelay.accept(.initial)
                    }
                    self.suggestionsRelay.accept([])
                } else if text.count < 2 {
                    self.stateRelay.accept(.suggesting(query: text))
                    self.suggestionsRelay.accept([])
                } else {
                    self.stateRelay.accept(.suggesting(query: text))
                    // 로컬 인덱스 기반 자동완성 (API 호출 없음)
                    let items = self.localSearch.suggestions(for: text)
                    self.suggestionsRelay.accept(items)
                }
            })
            .disposed(by: disposeBag)

        input.beginEditing
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.stateRelay.value != .initial {
                    self.stateRelay.accept(.initial)
                }
            })
            .disposed(by: disposeBag)

            // 검색 실행
        Observable.merge(
            input.searchTrigger,
            input.recentSearchTap,
            input.suggestionTap.map { $0.displayName }
        )
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .subscribe(onNext: { [weak self] query in
            guard let self else { return }
            self.stateRelay.accept(.result(query: query))
            self.recentSearchStore.save(query: query)
            self.fetchResults(query: query)
        })
        .disposed(by: disposeBag)

            // X 버튼 → 초기화
        input.clearTrigger
            .subscribe(onNext: { [weak self] in
                self?.stateRelay.accept(.landing)
                self?.brandResultsRelay.accept([])
                self?.perfumeResultsRelay.accept([])
                self?.suggestionsRelay.accept([])
            })
            .disposed(by: disposeBag)

            // 최근 검색어 개별 삭제
        input.deleteRecentSearch
            .subscribe(onNext: { [weak self] query in
                self?.recentSearchStore.delete(query: query)
            })
            .disposed(by: disposeBag)

            // 최근 검색어 전체 삭제
        input.clearAllRecentSearches
            .subscribe(onNext: { [weak self] in
                self?.recentSearchStore.clearAll()
            })
            .disposed(by: disposeBag)

            // 필터 변경
        input.filterChanged
            .bind(to: activeFilterRelay)
            .disposed(by: disposeBag)

            // 정렬 변경
        input.sortChanged
            .bind(to: currentSortRelay)
            .disposed(by: disposeBag)

            // 필터 + 정렬 적용된 향수 결과
        let filteredPerfumeResults = Observable.combineLatest(
            perfumeResultsRelay,
            activeFilterRelay,
            currentSortRelay
        )
            .map { perfumes, filter, sort -> [Perfume] in
                return SearchFilterEngine.apply(perfumes: perfumes, filter: filter, sort: sort)
            }

        let resultCount = filteredPerfumeResults.map { $0.count }

        return Output(
            state: stateRelay.asObservable(),
            recentSearches: recentSearchStore.searches,
            suggestions: suggestionsRelay.asObservable(),
            brandResults: brandResultsRelay.asObservable(),
            perfumeResults: perfumeResultsRelay.asObservable(),
            filteredPerfumeResults: filteredPerfumeResults,
            isLoading: isLoadingRelay.asObservable(),
            activeFilter: activeFilterRelay.asObservable(),
            currentSort: currentSortRelay.asObservable(),
            resultCount: resultCount
        )
    }

        // MARK: - Private

    private func fetchResults(query: String) {
        let requestQuery = PerfumeKoreanTranslator.toEnglishQuery(query) ?? query
        isLoadingRelay.accept(true)
        perfumeCatalogRepository.search(query: requestQuery, limit: 200)
            .subscribe(
                onSuccess: { [weak self] perfumes in
                    guard let self else { return }
                    self.isLoadingRelay.accept(false)
                    let rankedPerfumes = self.rankMatchingPerfumes(perfumes, for: query)
                    self.brandResultsRelay.accept(self.makeBrandResults(from: rankedPerfumes, query: query))
                    self.perfumeResultsRelay.accept(rankedPerfumes)
                },
                onFailure: { [weak self] _ in
                    self?.isLoadingRelay.accept(false)
                }
            )
            .disposed(by: disposeBag)
    }

    private func makeBrandResults(from perfumes: [Perfume], query: String) -> [Perfume] {
        let grouped = Dictionary(grouping: perfumes) { normalizeForSearch($0.brand) }

        return grouped.values
            .compactMap { group in
                group.max { lhs, rhs in
                    brandMatchScore(for: lhs, query: query) < brandMatchScore(for: rhs, query: query)
                }
            }
            .filter { brandMatchScore(for: $0, query: query) > 0 }
            .sorted {
                let lhsScore = brandMatchScore(for: $0, query: query)
                let rhsScore = brandMatchScore(for: $1, query: query)
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                let lhsPriority = PerfumeKoreanTranslator.domesticRetailPriority(for: $0)
                let rhsPriority = PerfumeKoreanTranslator.domesticRetailPriority(for: $1)
                if lhsPriority != rhsPriority { return lhsPriority > rhsPriority }
                return $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedAscending
            }
    }

    private func rankMatchingPerfumes(_ perfumes: [Perfume], for query: String) -> [Perfume] {
        perfumes
            .map { perfume in (perfume: perfume, score: searchScore(for: perfume, query: query)) }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                let lhsPriority = PerfumeKoreanTranslator.domesticRetailPriority(for: lhs.perfume)
                let rhsPriority = PerfumeKoreanTranslator.domesticRetailPriority(for: rhs.perfume)
                if lhsPriority != rhsPriority { return lhsPriority > rhsPriority }
                if lhs.perfume.brand != rhs.perfume.brand {
                    return lhs.perfume.brand.localizedCaseInsensitiveCompare(rhs.perfume.brand) == .orderedAscending
                }
                return lhs.perfume.name.localizedCaseInsensitiveCompare(rhs.perfume.name) == .orderedAscending
            }
            .map(\.perfume)
    }

    private func searchScore(for perfume: Perfume, query: String) -> Int {
        let normalizedQueries = searchQueryCandidates(for: query)
        guard !normalizedQueries.isEmpty else { return 0 }

        let normalizedBrandValues = searchableBrandValues(for: perfume).map(normalizeForSearch(_:))
        let normalizedNameValues = searchableNameValues(for: perfume).map(normalizeForSearch(_:))

        for normalizedQuery in normalizedQueries {
            if normalizedBrandValues.contains(normalizedQuery) { return 1_000 }
            if normalizedNameValues.contains(normalizedQuery) { return 900 }
            if normalizedBrandValues.contains(where: { $0.contains(normalizedQuery) }) { return 800 }
            if normalizedNameValues.contains(where: { $0.contains(normalizedQuery) }) { return 700 }
        }

        return 0
    }

    private func brandMatchScore(for perfume: Perfume, query: String) -> Int {
        let normalizedQueries = searchQueryCandidates(for: query)
        guard !normalizedQueries.isEmpty else { return 0 }

        let normalizedBrandValues = searchableBrandValues(for: perfume).map(normalizeForSearch(_:))

        for normalizedQuery in normalizedQueries {
            if normalizedBrandValues.contains(normalizedQuery) { return 1_000 }
            if normalizedBrandValues.contains(where: { $0.contains(normalizedQuery) }) { return 800 }
            // 쿼리가 브랜드명으로 시작하는 경우 (예: "크리드어벤투스" → 브랜드 "크리드" 매칭)
            if normalizedBrandValues.contains(where: { normalizedQuery.hasPrefix($0) && $0.count >= 2 }) { return 600 }
        }
        return 0
    }

    private func normalizeForSearch(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private func searchQueryCandidates(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [trimmed, PerfumeKoreanTranslator.toEnglishQuery(trimmed)]
            .compactMap { $0 }
            .map(normalizeForSearch(_:))
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    private func searchableBrandValues(for perfume: Perfume) -> [String] {
        uniqueSearchValues([perfume.brand, PerfumePresentationSupport.displayBrand(perfume.brand)] + perfume.brandAliases)
    }

    private func searchableNameValues(for perfume: Perfume) -> [String] {
        uniqueSearchValues([perfume.name, PerfumePresentationSupport.displayPerfumeName(perfume.name)] + perfume.nameAliases)
    }

    private func uniqueSearchValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert(normalizeForSearch($0)).inserted }
    }
}
