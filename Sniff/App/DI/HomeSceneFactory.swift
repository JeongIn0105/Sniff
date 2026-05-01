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
        let viewModel = HomeViewModel(
            userTasteRepository: dependencyContainer.makeUserTasteRepository(),
            collectionRepository: collectionRepository,
            tastingRecordRepository: dependencyContainer.makeTastingRecordRepository(),
            recommendPerfumesUseCase: dependencyContainer.makeRecommendPerfumesUseCase()
        )
        return HomeViewController(
            viewModel: viewModel,
            collectionRepository: collectionRepository,
            tastingRecordRepository: dependencyContainer.makeTastingRecordRepository(),
            localTastingNoteRepository: dependencyContainer.localTastingNoteRepository
        )
    }
}
