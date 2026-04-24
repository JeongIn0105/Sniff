//
//  SearchSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum SearchSceneFactory {

    static func makeSearchViewController() -> SearchViewController {
        makeSearchViewController(dependencyContainer: AppDependencyContainer(), showsRecentOnAppear: false)
    }

    static func makeSearchViewController(
        dependencyContainer: AppDependencyContainer,
        showsRecentOnAppear: Bool = false
    ) -> SearchViewController {
        let viewModel = SearchViewModel(
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository(),
            recentSearchStore: dependencyContainer.makeRecentSearchStore(),
            initialState: showsRecentOnAppear ? .initial : .landing
        )
        return SearchViewController(
            viewModel: viewModel,
            collectionRepository: dependencyContainer.makeCollectionRepository(),
            showsRecentOnAppear: showsRecentOnAppear
        )
    }
}
