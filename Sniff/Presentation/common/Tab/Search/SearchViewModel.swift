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
    private let searchPerfumesUseCase: SearchPerfumesUseCaseType
    private let recentSearchStore: RecentSearchStoreType
    private let disposeBag = DisposeBag()

        // MARK: - State
    private let stateRelay = BehaviorRelay<SearchState>(value: .initial)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let brandResultsRelay = BehaviorRelay<[Perfume]>(value: [])
    private let perfumeResultsRelay = BehaviorRelay<[Perfume]>(value: [])
    private let suggestionsRelay = BehaviorRelay<[SuggestionItem]>(value: [])
    private let activeFilterRelay = BehaviorRelay<SearchFilter>(value: SearchFilter())
    private let currentSortRelay = BehaviorRelay<SortOption>(value: .recommended)

        // MARK: - Init
    init(
        searchPerfumesUseCase: SearchPerfumesUseCaseType,
        recentSearchStore: RecentSearchStoreType = RecentSearchStore()
    ) {
        self.searchPerfumesUseCase = searchPerfumesUseCase
        self.recentSearchStore = recentSearchStore
    }

        // MARK: - Transform
    func transform(input: Input) -> Output {

            // 텍스트 입력 → 상태 전환
        input.searchText
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                guard let self else { return }
                if text.isEmpty {
                    self.stateRelay.accept(.initial)
                    self.suggestionsRelay.accept([])
                } else {
                    self.stateRelay.accept(.suggesting(query: text))
                    self.fetchSuggestions(query: text)
                }
            })
            .disposed(by: disposeBag)

            // 검색 실행
        Observable.merge(
            input.searchTrigger,
            input.recentSearchTap,
            input.suggestionTap.map { $0.displayName }
        )
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
                self?.stateRelay.accept(.initial)
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
            .map { [weak self] perfumes, filter, sort -> [Perfume] in
                guard let self else { return perfumes }
                return self.applyFilterAndSort(perfumes: perfumes, filter: filter, sort: sort)
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

    private func fetchSuggestions(query: String) {
        searchPerfumesUseCase.execute(query: query, limit: 5)
            .subscribe(onSuccess: { [weak self] perfumes in
                guard let self else { return }
                var items: [SuggestionItem] = []

                    // 브랜드 중복 제거
                let brands = Array(Set(perfumes.map { $0.brand })).prefix(3)
                items += brands.map { .brand(name: $0) }

                    // 향수명
                items += perfumes.prefix(5).map {
                    .perfume(name: $0.name, brand: $0.brand)
                }

                self.suggestionsRelay.accept(items)
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func fetchResults(query: String) {
        isLoadingRelay.accept(true)
        searchPerfumesUseCase.execute(query: query, limit: 50)
            .subscribe(
                onSuccess: { [weak self] perfumes in
                    guard let self else { return }
                    self.isLoadingRelay.accept(false)

                        // 브랜드 필터링 — 쿼리가 브랜드명과 일치하는 경우
                    let brands = perfumes.filter {
                        $0.brand.lowercased().contains(query.lowercased())
                    }
                        // 중복 제거 (브랜드 이름 기준)
                    let uniqueBrands = Array(
                        Dictionary(grouping: brands, by: { $0.brand })
                            .compactMapValues { $0.first }
                            .values
                    )
                    self.brandResultsRelay.accept(uniqueBrands)
                    self.perfumeResultsRelay.accept(perfumes)
                },
                onFailure: { [weak self] _ in
                    self?.isLoadingRelay.accept(false)
                }
            )
            .disposed(by: disposeBag)
    }

    private func applyFilterAndSort(
        perfumes: [Perfume],
        filter: SearchFilter,
        sort: SortOption
    ) -> [Perfume] {
        var result = perfumes

            // 무드&이미지 필터
        if !filter.moodTags.isEmpty {
            let targetAccords = Set(filter.moodTags.flatMap { $0.relatedAccords })
            result = result.filter { perfume in
                let perfumeAccords = Set(perfume.mainAccords.map { $0.lowercased() })
                return !perfumeAccords.isDisjoint(with: targetAccords)
            }
        }

            // 농도 필터
        if !filter.concentrations.isEmpty {
            let targetValues = Set(filter.concentrations.flatMap { $0.fragellaValues })
            result = result.filter { perfume in
                guard let conc = perfume.concentration?.lowercased() else { return false }
                return targetValues.contains(conc)
            }
        }

            // 계절 필터
        if !filter.seasons.isEmpty {
            let targetSeasons = filter.seasons.compactMap { $0.fragellaValue }
            if !targetSeasons.isEmpty { // 사계절만 선택된 경우 필터 없음
                result = result.filter { perfume in
                    guard let seasons = perfume.season else { return false }
                    return seasons.contains { targetSeasons.contains($0) }
                }
            }
        }

            // 정렬
        switch sort {
            case .recommended:
                break // API 기본 순서 유지
            case .newest:
                break // Fragella에 날짜 정보 없음 → 순서 유지
            case .nameAsc:
                result.sort { $0.name < $1.name }
            case .nameDesc:
                result.sort { $0.name > $1.name }
        }

        return result
    }
}
