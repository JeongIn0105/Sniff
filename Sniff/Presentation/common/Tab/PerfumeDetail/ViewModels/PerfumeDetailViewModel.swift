    //
    //  PerfumeDetailViewModel.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.13.
    //

import Foundation
import RxSwift
import RxCocoa

final class PerfumeDetailViewModel {

        // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let addToCollectionTap: Observable<Void>
        let addTastingRecordTap: Observable<Void>
    }

        // MARK: - Output
    struct Output {
        let perfume: Driver<Perfume?>
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String?>
        let onAddToCollection: Observable<Perfume>
        let onAddTastingRecord: Observable<Perfume>
    }

        // MARK: - Properties
    private let perfumeId: String
    private let perfumeCatalogRepository: PerfumeCatalogRepositoryType
    private let seedPerfume: Perfume?
    private let disposeBag = DisposeBag()

    private let perfumeRelay = BehaviorRelay<Perfume?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

        // MARK: - Init
    init(perfumeId: String, perfumeCatalogRepository: PerfumeCatalogRepositoryType) {
        self.perfumeId = perfumeId
        self.perfumeCatalogRepository = perfumeCatalogRepository
        self.seedPerfume = nil
    }

    init(perfume: Perfume, perfumeCatalogRepository: PerfumeCatalogRepositoryType) {
        self.perfumeId = perfume.id
        self.perfumeCatalogRepository = perfumeCatalogRepository
        self.seedPerfume = perfume
        self.perfumeRelay.accept(perfume)
    }

        // MARK: - Transform
    func transform(input: Input) -> Output {

        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.loadDetailIfNeeded()
            })
            .disposed(by: disposeBag)

        let perfume = perfumeRelay.asDriver()

        let onAddToCollection = input.addToCollectionTap
            .compactMap { [weak self] in self?.perfumeRelay.value }

        let onAddTastingRecord = input.addTastingRecordTap
            .compactMap { [weak self] in self?.perfumeRelay.value }

        return Output(
            perfume: perfume,
            isLoading: isLoadingRelay.asDriver(),
            errorMessage: errorRelay.asDriver(),
            onAddToCollection: onAddToCollection,
            onAddTastingRecord: onAddTastingRecord
        )
    }

        // MARK: - Private
    private func loadDetailIfNeeded() {
        let currentPerfume = perfumeRelay.value
        let needsDetailFetch = currentPerfume?.needsDetailEnrichment ?? true
        guard needsDetailFetch else { return }
        guard currentPerfume?.canFetchRemoteDetail ?? true else { return }

        let shouldShowLoading = currentPerfume == nil
        fetchDetail(showLoading: shouldShowLoading)
    }

    private func fetchDetail(showLoading: Bool) {
        if showLoading {
            isLoadingRelay.accept(true)
        }

        detailRequest()
            .subscribe(
                onSuccess: { [weak self] perfume in
                    if showLoading {
                        self?.isLoadingRelay.accept(false)
                    }
                    self?.perfumeRelay.accept(perfume)
                },
                onFailure: { [weak self] error in
                    self?.isLoadingRelay.accept(false)

                    if self?.seedPerfume == nil {
                        self?.errorRelay.accept(error.localizedDescription)
                    }
                }
            )
            .disposed(by: disposeBag)
    }

    private func detailRequest() -> Single<Perfume> {
        let directRequest = perfumeCatalogRepository.fetchDetail(perfumeId: perfumeId)

        guard let seedPerfume else {
            return directRequest
        }

        return directRequest
            .catch { [weak self] _ in
                guard let self else { return .just(seedPerfume) }
                return self.searchFallbackDetail(for: seedPerfume)
            }
            .catchAndReturn(seedPerfume)
    }

    private func searchFallbackDetail(for perfume: Perfume) -> Single<Perfume> {
        let query = "\(perfume.brand) \(perfume.name)"

        return perfumeCatalogRepository.search(query: query, limit: 30)
            .flatMap { [weak self] results in
                guard
                    let self,
                    let matched = self.bestMatchedPerfume(in: results, target: perfume)
                else {
                    return .just(perfume)
                }

                return self.perfumeCatalogRepository.fetchDetail(perfumeId: matched.id)
                    .catchAndReturn(matched)
            }
    }

    private func bestMatchedPerfume(in perfumes: [Perfume], target: Perfume) -> Perfume? {
        let normalizedTargetName = normalize(target.name)
        let normalizedTargetBrand = normalize(target.brand)

        return perfumes.first {
            normalize($0.name) == normalizedTargetName &&
            normalize($0.brand) == normalizedTargetBrand
        } ?? perfumes.first {
            normalize($0.name).contains(normalizedTargetName) &&
            normalize($0.brand) == normalizedTargetBrand
        } ?? perfumes.first {
            normalize($0.name) == normalizedTargetName
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
    }
}

private extension Perfume {
    var needsDetailEnrichment: Bool {
        let hasCompleteNotes = !(topNotes?.isEmpty ?? true)
            && !(middleNotes?.isEmpty ?? true)
            && !(baseNotes?.isEmpty ?? true)
        let hasSeasonInfo = !seasonRanking.isEmpty || !(season?.isEmpty ?? true)
        let hasOccasionInfo = !occasionRanking.isEmpty || !(situation?.isEmpty ?? true)
        let hasUsageInfo = !(concentration?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            && !(longevity?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            && !(sillage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        return !(hasCompleteNotes && hasSeasonInfo && hasOccasionInfo && hasUsageInfo)
    }

    var canFetchRemoteDetail: Bool {
        let syntheticID = "\(brand)-\(name)"
        return id != syntheticID
    }
}
