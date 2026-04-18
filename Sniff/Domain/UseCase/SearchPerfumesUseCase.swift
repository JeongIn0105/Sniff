//
//  SearchPerfumesUseCase.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol SearchPerfumesUseCaseType {
    func execute(query: String, limit: Int) -> Single<[Perfume]>
}

final class SearchPerfumesUseCase: SearchPerfumesUseCaseType {

    private let repository: PerfumeCatalogRepositoryType

    init(repository: PerfumeCatalogRepositoryType) {
        self.repository = repository
    }

    func execute(query: String, limit: Int) -> Single<[Perfume]> {
        repository.search(query: query, limit: limit)
    }
}
