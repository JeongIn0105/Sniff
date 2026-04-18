//
//  PerfumeDetailSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum PerfumeDetailSceneFactory {

    static func makeViewController(perfume: Perfume) -> PerfumeDetailViewController {
        let repository = PerfumeCatalogRepository()
        let useCase = FetchPerfumeDetailUseCase(repository: repository)
        let viewModel = PerfumeDetailViewModel(
            perfume: perfume,
            fetchPerfumeDetailUseCase: useCase
        )
        return PerfumeDetailViewController(viewModel: viewModel)
    }

    static func makeViewController(perfumeId: String) -> PerfumeDetailViewController {
        let repository = PerfumeCatalogRepository()
        let useCase = FetchPerfumeDetailUseCase(repository: repository)
        let viewModel = PerfumeDetailViewModel(
            perfumeId: perfumeId,
            fetchPerfumeDetailUseCase: useCase
        )
        return PerfumeDetailViewController(viewModel: viewModel)
    }
}
