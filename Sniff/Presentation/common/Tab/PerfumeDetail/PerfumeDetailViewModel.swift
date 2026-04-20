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
        let perfumeName: Driver<String>
        let brandName: Driver<String>
        let imageURL: Driver<String?>
        let notesText: Driver<String>

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
            .filter { [weak self] _ in self?.perfumeRelay.value == nil }
            .subscribe(onNext: { [weak self] in
                self?.fetchDetail()
            })
            .disposed(by: disposeBag)

        let perfume = perfumeRelay.asDriver()

        let perfumeName = perfumeRelay
            .map { $0?.name ?? "" }
            .asDriver(onErrorJustReturn: "")

        let brandName = perfumeRelay
            .map { $0?.brand ?? "" }
            .asDriver(onErrorJustReturn: "")

        let imageURL = perfumeRelay
            .map { $0?.imageUrl }
            .asDriver(onErrorJustReturn: nil)

        let notesText = perfumeRelay
            .map { perfume in
                guard let perfume else { return "" }

                let top = perfume.topNotes?.joined(separator: ", ") ?? "-"
                let middle = perfume.middleNotes?.joined(separator: ", ") ?? "-"
                let base = perfume.baseNotes?.joined(separator: ", ") ?? "-"

                return "TOP: \(top)\n\nMIDDLE: \(middle)\n\nBASE: \(base)"
            }
            .asDriver(onErrorJustReturn: "")

        let onAddToCollection = input.addToCollectionTap
            .compactMap { [weak self] in self?.perfumeRelay.value }

        let onAddTastingRecord = input.addTastingRecordTap
            .compactMap { [weak self] in self?.perfumeRelay.value }

        return Output(
            perfume: perfume,
            perfumeName: perfumeName,
            brandName: brandName,
            imageURL: imageURL,
            notesText: notesText,
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
