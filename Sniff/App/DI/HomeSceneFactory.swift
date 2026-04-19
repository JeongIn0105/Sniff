//
//  HomeSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum HomeSceneFactory {

    static func makeViewController() -> HomeViewController {
        let userTasteRepository = UserTasteRepository()
        let collectionRepository = CollectionRepository()
        let tastingRecordRepository = TastingRecordRepository()
        let perfumeCatalogRepository = PerfumeCatalogRepository()

        let recommendationEngine = RecommendationEngine(
            perfumeCatalogRepository: perfumeCatalogRepository
        )
        let recommendPerfumesUseCase = RecommendPerfumesUseCase(
            recommendationEngine: recommendationEngine
        )
        let viewModel = HomeViewModel(
            userTasteRepository: userTasteRepository,
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository,
            recommendPerfumesUseCase: recommendPerfumesUseCase
        )
        return HomeViewController(viewModel: viewModel)
    }
}
