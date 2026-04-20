
    //
    //  Created by t2025-m0239 on 2026.04.13.
    //
    // PerfumeDetailViewModel.swift
    // Sniff — 향수 상세 ViewModel

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
        // perfumeId로 API 조회하는 경우
    init(perfumeId: String, perfumeCatalogRepository: PerfumeCatalogRepositoryType) {
        self.perfumeId = perfumeId
        self.perfumeCatalogRepository = perfumeCatalogRepository
    }

        // 이미 데이터가 있는 경우 (검색 결과에서 넘어올 때) — API 재호출 불필요
    init(perfume: Perfume, perfumeCatalogRepository: PerfumeCatalogRepositoryType) {
        self.perfumeId = perfume.id
        self.perfumeCatalogRepository = perfumeCatalogRepository
        self.perfumeRelay.accept(perfume)
    }

        // MARK: - Transform
    func transform(input: Input) -> Output {

            // viewDidLoad 시 데이터가 없으면 API 호출
        input.viewDidLoad
            .filter { [weak self] _ in self?.perfumeRelay.value == nil }
            .subscribe(onNext: { [weak self] in
                self?.fetchDetail()
            })
            .disposed(by: disposeBag)

        let onAddToCollection = input.addToCollectionTap
            .compactMap { [weak self] in self?.perfumeRelay.value }

        let onAddTastingRecord = input.addTastingRecordTap
            .compactMap { [weak self] in self?.perfumeRelay.value }

        return Output(
            perfume: perfumeRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            errorMessage: errorRelay.asDriver(),
            onAddToCollection: onAddToCollection,
            onAddTastingRecord: onAddTastingRecord
        )
    }

        // MARK: - Private
    private func fetchDetail() {
        isLoadingRelay.accept(true)
        perfumeCatalogRepository.fetchDetail(perfumeId: perfumeId)
            .subscribe(
                onSuccess: { [weak self] perfume in
                    self?.isLoadingRelay.accept(false)
                    self?.perfumeRelay.accept(perfume)
                },
                onFailure: { [weak self] error in
                    self?.isLoadingRelay.accept(false)
                    self?.errorRelay.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
}

