//
//  SearchSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum SearchSceneFactory {

    static func makeSearchViewController() -> SearchViewController {
        makeSearchViewController(dependencyContainer: AppDependencyContainer())
    }

    static func makeSearchViewController(
        dependencyContainer: AppDependencyContainer
    ) -> SearchViewController {
        let viewModel = SearchViewModel(
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository(),
            recentSearchStore: dependencyContainer.makeRecentSearchStore()
        )
        return SearchViewController(
            viewModel: viewModel,
            collectionRepository: dependencyContainer.makeCollectionRepository()
        )
    }
}
