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

        let fetchHomeFeedUseCase = FetchHomeFeedUseCase(
            userTasteRepository: userTasteRepository,
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository
        )
        let recommendationEngine = RecommendationEngine(
            perfumeCatalogRepository: perfumeCatalogRepository
        )
        let recommendPerfumesUseCase = RecommendPerfumesUseCase(
            recommendationEngine: recommendationEngine
        )
        let viewModel = HomeViewModel(
            fetchHomeFeedUseCase: fetchHomeFeedUseCase,
            recommendPerfumesUseCase: recommendPerfumesUseCase
        )
        return HomeViewController(viewModel: viewModel)
    }
}
