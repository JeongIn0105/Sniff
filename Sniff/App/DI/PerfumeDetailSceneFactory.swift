//
//  PerfumeDetailSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import UIKit

@MainActor
enum PerfumeDetailSceneFactory {

    static func makeViewController(perfume: Perfume) -> UIViewController {
        makeViewController(perfume: perfume, dependencyContainer: AppDependencyContainer())
    }

    static func makeViewController(
        perfume: Perfume,
        dependencyContainer: AppDependencyContainer
    ) -> UIViewController {
        let collectionRepository = dependencyContainer.makeCollectionRepository()
        let tastingRecordRepository = dependencyContainer.makeTastingRecordRepository()
        let viewModel = PerfumeDetailScreenViewModel(
            perfume: perfume,
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository(),
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository
        )
        return configuredDetailViewController(PerfumeDetailHostingController(viewModel: viewModel))
    }

    static func makeViewController(perfumeId: String) -> UIViewController {
        makeViewController(perfumeId: perfumeId, dependencyContainer: AppDependencyContainer())
    }

    static func makeViewController(
        perfumeId: String,
        dependencyContainer: AppDependencyContainer
    ) -> UIViewController {
        let collectionRepository = dependencyContainer.makeCollectionRepository()
        let tastingRecordRepository = dependencyContainer.makeTastingRecordRepository()
        let viewModel = PerfumeDetailScreenViewModel(
            perfumeId: perfumeId,
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository(),
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository
        )
        return configuredDetailViewController(PerfumeDetailHostingController(viewModel: viewModel))
    }

    private static func configuredDetailViewController(
        _ viewController: UIViewController
    ) -> UIViewController {
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
}
