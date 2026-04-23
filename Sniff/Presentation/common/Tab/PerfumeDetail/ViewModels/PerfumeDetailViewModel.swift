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
    private let disposeBag = DisposeBag()

    private let perfumeRelay = BehaviorRelay<Perfume?>(value: nil)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

        // MARK: - Init
    init(perfumeId: String, perfumeCatalogRepository: PerfumeCatalogRepositoryType) {
        self.perfumeId = perfumeId
        self.perfumeCatalogRepository = perfumeCatalogRepository
    }

    init(perfume: Perfume, perfumeCatalogRepository: PerfumeCatalogRepositoryType) {
        self.perfumeId = perfume.id
        self.perfumeCatalogRepository = perfumeCatalogRepository
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

        perfumeCatalogRepository.fetchDetail(perfumeId: perfumeId)
            .subscribe(
                onSuccess: { [weak self] perfume in
                    if showLoading {
                        self?.isLoadingRelay.accept(false)
                    }
                    self?.perfumeRelay.accept(perfume)
                },
                onFailure: { [weak self] error in
                    if showLoading {
                        self?.isLoadingRelay.accept(false)
                        self?.errorRelay.accept(error.localizedDescription)
                    }
                }
            )
            .disposed(by: disposeBag)
    }
}

private extension Perfume {
    var needsDetailEnrichment: Bool {
        let hasCompleteNotes = !(topNotes?.isEmpty ?? true)
            && !(middleNotes?.isEmpty ?? true)
            && !(baseNotes?.isEmpty ?? true)
        let hasSeasonInfo = !seasonRanking.isEmpty || !(season?.isEmpty ?? true)
        let hasUsageInfo = !(concentration?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            && !(longevity?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            && !(sillage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        return !(hasCompleteNotes && hasSeasonInfo && hasUsageInfo)
    }

    var canFetchRemoteDetail: Bool {
        let syntheticID = "\(brand)-\(name)"
        return id != syntheticID
    }
}
