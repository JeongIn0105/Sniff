//
//  HomeSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum HomeSceneFactory {

    static func makeViewController() -> HomeViewController {
        makeViewController(dependencyContainer: AppDependencyContainer())
    }

    static func makeViewController(
        dependencyContainer: AppDependencyContainer
    ) -> HomeViewController {
        let collectionRepository = dependencyContainer.makeCollectionRepository()
        let tastingRecordRepository = dependencyContainer.makeTastingRecordRepository()
        let userTasteRepository = dependencyContainer.makeUserTasteRepository()
        let viewModel = HomeViewModel(
            userTasteRepository: userTasteRepository,
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository,
            recommendPerfumesUseCase: dependencyContainer.makeRecommendPerfumesUseCase()
        )
        return HomeViewController(
            viewModel: viewModel,
            userTasteRepository: userTasteRepository,
            collectionRepository: collectionRepository,
            tastingRecordRepository: tastingRecordRepository,
            localTastingNoteRepository: dependencyContainer.localTastingNoteRepository
        )
    }
}
