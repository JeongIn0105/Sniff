//
//  FetchPerfumeDetailUseCase.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol FetchPerfumeDetailUseCaseType {
    func execute(perfumeId: String) -> Single<Perfume>
}

final class FetchPerfumeDetailUseCase: FetchPerfumeDetailUseCaseType {

    private let repository: PerfumeCatalogRepositoryType

    init(repository: PerfumeCatalogRepositoryType) {
        self.repository = repository
    }

    func execute(perfumeId: String) -> Single<Perfume> {
        repository.fetchDetail(perfumeId: perfumeId)
    }
}
