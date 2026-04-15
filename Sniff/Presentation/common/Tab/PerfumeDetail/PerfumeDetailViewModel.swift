//
//  ViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import RxSwift
import RxCocoa

final class PerfumeDetailViewModel {

    struct Input {
        let viewDidLoad: Observable<Void>
    }

    struct Output {
        let perfumeName: Driver<String>
        let brandName: Driver<String>
        let imageURL: Driver<String?>
        let notesText: Driver<String>
    }

    private let perfumeId: String
    private let disposeBag = DisposeBag()

    init(perfumeId: String) {
        self.perfumeId = perfumeId
    }

    func transform(input: Input) -> Output {

        let perfumeRelay = PublishRelay<FragellaPerfume>()

        input.viewDidLoad
            .flatMapLatest { _ in
                FragellaService.shared.fetchDetail(perfumeId: self.perfumeId)
            }
            .bind(to: perfumeRelay)
            .disposed(by: disposeBag)

        let name = perfumeRelay
            .map { $0.name }
            .asDriver(onErrorJustReturn: "")

        let brand = perfumeRelay
            .map { $0.brand }
            .asDriver(onErrorJustReturn: "")

        let imageURL = perfumeRelay
            .map { $0.imageUrl }
            .asDriver(onErrorJustReturn: nil)

        let notes = perfumeRelay
            .map { perfume in
                let top = perfume.topNotes?.joined(separator: ", ") ?? "-"
                let middle = perfume.middleNotes?.joined(separator: ", ") ?? "-"
                let base = perfume.baseNotes?.joined(separator: ", ") ?? "-"

                return """
                TOP: \(top)
                
                MIDDLE: \(middle)
                
                BASE: \(base)
                """
            }
            .asDriver(onErrorJustReturn: "")

        return Output(
            perfumeName: name,
            brandName: brand,
            imageURL: imageURL,
            notesText: notes
        )
    }
}
