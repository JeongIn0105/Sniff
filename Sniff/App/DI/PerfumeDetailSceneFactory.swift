//
//  PerfumeDetailSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum PerfumeDetailSceneFactory {

    static func makeViewController(perfume: Perfume) -> PerfumeDetailViewController {
        makeViewController(perfume: perfume, dependencyContainer: AppDependencyContainer())
    }

    static func makeViewController(
        perfume: Perfume,
        dependencyContainer: AppDependencyContainer
    ) -> PerfumeDetailViewController {
        let collectionRepository = dependencyContainer.makeCollectionRepository()
        let viewModel = PerfumeDetailViewModel(
            perfume: perfume,
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository()
        )
        return PerfumeDetailViewController(
            viewModel: viewModel,
            collectionRepository: collectionRepository
        )
    }

    static func makeViewController(perfumeId: String) -> PerfumeDetailViewController {
        makeViewController(perfumeId: perfumeId, dependencyContainer: AppDependencyContainer())
    }

    static func makeViewController(
        perfumeId: String,
        dependencyContainer: AppDependencyContainer
    ) -> PerfumeDetailViewController {
        let collectionRepository = dependencyContainer.makeCollectionRepository()
        let viewModel = PerfumeDetailViewModel(
            perfumeId: perfumeId,
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository()
        )
        return PerfumeDetailViewController(
            viewModel: viewModel,
            collectionRepository: collectionRepository
        )
    }
}
