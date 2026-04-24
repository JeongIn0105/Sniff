//
//  FilterViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

    // FilterViewModel.swift
    // 킁킁(Sniff) - 필터 ViewModel

import Foundation
import RxSwift
import RxRelay

final class FilterViewModel {

    private enum SelectionLimit {
        static let scentFamilies = 3
    }

        // MARK: - Input
    struct Input {
        let scentFamilyToggle: Observable<ScentFamilyFilter>
        let moodTagToggle: Observable<MoodTag>
        let concentrationToggle: Observable<Concentration>
        let seasonToggle: Observable<Season>
        let resetTrigger: Observable<Void>
        let applyTrigger: Observable<Void>
    }

        // MARK: - Output
    struct Output {
        let currentFilter: Observable<SearchFilter>
        let resultCount: Observable<Int>
        let isApplyEnabled: Observable<Bool>
        let onApply: Observable<SearchFilter>
    }

        // MARK: - State
    private let filterRelay: BehaviorRelay<SearchFilter>
    private let resultCountRelay = BehaviorRelay<Int>(value: 0)
    private let disposeBag = DisposeBag()

        // 외부에서 현재 향수 목록 주입
    var currentPerfumes: [Perfume] = []

    init(initialFilter: SearchFilter = SearchFilter()) {
        var sanitizedFilter = initialFilter
        sanitizedFilter.moodTags = []
        self.filterRelay = BehaviorRelay(value: sanitizedFilter)
    }

    func transform(input: Input) -> Output {
        updateResultCount(filter: filterRelay.value)

        input.scentFamilyToggle
            .subscribe(onNext: { [weak self] family in
                guard let self else { return }
                var filter = self.filterRelay.value
                if filter.scentFamilies.contains(family) {
                    filter.scentFamilies.remove(family)
                } else if filter.scentFamilies.count < SelectionLimit.scentFamilies {
                    filter.scentFamilies.insert(family)
                } else {
                    return
                }
                self.filterRelay.accept(filter)
                self.updateResultCount(filter: filter)
            })
            .disposed(by: disposeBag)

            // 농도 토글
        input.concentrationToggle
            .subscribe(onNext: { [weak self] conc in
                guard let self else { return }
                var filter = self.filterRelay.value
                if filter.concentrations.contains(conc) {
                    filter.concentrations.remove(conc)
                } else {
                    filter.concentrations = [conc]
                }
                self.filterRelay.accept(filter)
                self.updateResultCount(filter: filter)
            })
            .disposed(by: disposeBag)

            // 계절 토글
        input.seasonToggle
            .subscribe(onNext: { [weak self] season in
                guard let self else { return }
                var filter = self.filterRelay.value
                if filter.seasons.contains(season) {
                    filter.seasons.remove(season)
                } else {
                    filter.seasons.insert(season)
                }
                self.filterRelay.accept(filter)
                self.updateResultCount(filter: filter)
            })
            .disposed(by: disposeBag)

            // 초기화
        input.resetTrigger
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let filter = SearchFilter()
                self.filterRelay.accept(filter)
                self.resultCountRelay.accept(self.currentPerfumes.count)
            })
            .disposed(by: disposeBag)

        let isApplyEnabled = Observable
            .combineLatest(filterRelay.asObservable(), resultCountRelay.asObservable())
            .map { !$0.0.isEmpty && $0.1 > 0 }

        let onApply = input.applyTrigger
            .withLatestFrom(filterRelay)

        return Output(
            currentFilter: filterRelay.asObservable(),
            resultCount: resultCountRelay.asObservable(),
            isApplyEnabled: isApplyEnabled,
            onApply: onApply
        )
    }

        // MARK: - Private

    private func updateResultCount(filter: SearchFilter) {
        let count = SearchFilterEngine.filterPerfumes(currentPerfumes, filter: filter).count
        resultCountRelay.accept(count)
    }
}
