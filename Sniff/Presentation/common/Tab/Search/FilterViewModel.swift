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

        // MARK: - Input
    struct Input {
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
        self.filterRelay = BehaviorRelay(value: initialFilter)
    }

    func transform(input: Input) -> Output {
        updateResultCount(filter: filterRelay.value)

            // 무드 태그 토글
        input.moodTagToggle
            .subscribe(onNext: { [weak self] tag in
                guard let self else { return }
                var filter = self.filterRelay.value
                if filter.moodTags.contains(tag) {
                    filter.moodTags.remove(tag)
                } else {
                    filter.moodTags.insert(tag)
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
                    filter.concentrations.insert(conc)
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

        let isApplyEnabled = resultCountRelay.map { $0 > 0 }

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
        let count = applyFilter(perfumes: currentPerfumes, filter: filter).count
        resultCountRelay.accept(count)
    }

    private func applyFilter(perfumes: [Perfume], filter: SearchFilter) -> [Perfume] {
        var result = perfumes

        if !filter.moodTags.isEmpty {
            let targetAccords = Set(filter.moodTags.flatMap { $0.relatedAccords })
            result = result.filter { perfume in
                let accords = Set(perfume.mainAccords.map { $0.lowercased() })
                return !accords.isDisjoint(with: targetAccords)
            }
        }

        if !filter.concentrations.isEmpty {
            let targetValues = Set(filter.concentrations.flatMap { $0.fragellaValues })
            result = result.filter { perfume in
                guard let conc = perfume.concentration?.lowercased() else { return false }
                return targetValues.contains(conc)
            }
        }

        if !filter.seasons.isEmpty {
            let targetSeasons = filter.seasons.compactMap { $0.fragellaValue }
            if !targetSeasons.isEmpty {
                result = result.filter { perfume in
                    guard let seasons = perfume.season else { return false }
                    return seasons.contains { targetSeasons.contains($0) }
                }
            }
        }

        return result
    }
}
