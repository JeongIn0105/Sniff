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
            .flatMapLatest { [weak self] _ -> Single<FragellaPerfume> in
                guard let self else { return .error(FragellaError.invalidURL) }
                return FragellaService.shared.fetchDetail(perfumeId: self.perfumeId)
            }
            .asObservable()
            .catch { error in
                print("[PerfumeDetail Debug] perfumeId: \(self.perfumeId)")
                print("[PerfumeDetail Debug] localizedDescription: \(error.localizedDescription)")
                let nsError = error as NSError
                print("[PerfumeDetail Debug] NSError domain: \(nsError.domain), code: \(nsError.code)")
                return .empty()
            }
            .bind(to: perfumeRelay)
            .disposed(by: disposeBag)

        let name = perfumeRelay.map { $0.name }.asDriver(onErrorJustReturn: "")
        let brand = perfumeRelay.map { $0.brand }.asDriver(onErrorJustReturn: "")
        let imageURL = perfumeRelay.map { $0.imageUrl }.asDriver(onErrorJustReturn: nil)

        let notes = perfumeRelay
            .map { perfume in
                let top = perfume.topNotes?.joined(separator: ", ") ?? "-"
                let middle = perfume.middleNotes?.joined(separator: ", ") ?? "-"
                let base = perfume.baseNotes?.joined(separator: ", ") ?? "-"

                return "TOP: \(top)\n\nMIDDLE: \(middle)\n\nBASE: \(base)"
            }
            .asDriver(onErrorJustReturn: "")

        return Output(perfumeName: name, brandName: brand, imageURL: imageURL, notesText: notes)
    }
}
