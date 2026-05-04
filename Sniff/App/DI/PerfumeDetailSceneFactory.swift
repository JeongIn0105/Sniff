//
//  PerfumeDetailSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import UIKit

enum PerfumeDetailSceneFactory {

    static func makeViewController(perfume: Perfume) -> PerfumeDetailViewController {
        makeViewController(perfume: perfume, dependencyContainer: AppDependencyContainer())
    }

    static func makeViewController(
        perfume: Perfume,
        dependencyContainer: AppDependencyContainer
    ) -> PerfumeDetailViewController {
        let collectionRepository = dependencyContainer.makeCollectionRepository()
        let tastingRecordRepository = dependencyContainer.makeTastingRecordRepository()
        let viewModel = PerfumeDetailViewModel(
            perfume: perfume,
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository()
        )
        return configuredDetailViewController(PerfumeDetailViewController(
            viewModel: viewModel,
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository
        ))
    }

    static func makeViewController(perfumeId: String) -> PerfumeDetailViewController {
        makeViewController(perfumeId: perfumeId, dependencyContainer: AppDependencyContainer())
    }

    static func makeViewController(
        perfumeId: String,
        dependencyContainer: AppDependencyContainer
    ) -> PerfumeDetailViewController {
        let collectionRepository = dependencyContainer.makeCollectionRepository()
        let tastingRecordRepository = dependencyContainer.makeTastingRecordRepository()
        let viewModel = PerfumeDetailViewModel(
            perfumeId: perfumeId,
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository()
        )
        return configuredDetailViewController(PerfumeDetailViewController(
            viewModel: viewModel,
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository
        ))
    }

    private static func configuredDetailViewController(
        _ viewController: PerfumeDetailViewController
    ) -> PerfumeDetailViewController {
        viewController.hidesBottomBarWhenPushed = false
        return viewController
    }
}
