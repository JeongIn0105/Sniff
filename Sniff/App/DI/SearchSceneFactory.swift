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
        showsRecentOnAppear: Bool = false,
        mode: PerfumeSearchMode
    ) -> SearchViewController {
        makeSearchViewController(
            dependencyContainer: AppDependencyContainer(),
            showsRecentOnAppear: showsRecentOnAppear,
            mode: mode
        )
    }

    static func makeSearchViewController(
        dependencyContainer: AppDependencyContainer,
        showsRecentOnAppear: Bool = false,
        mode: PerfumeSearchMode = .browse
    ) -> SearchViewController {
        let viewModel = SearchViewModel(
            perfumeCatalogRepository: dependencyContainer.makePerfumeCatalogRepository(),
            recentSearchStore: dependencyContainer.makeRecentSearchStore(),
            initialState: showsRecentOnAppear ? .initial : .landing
        )
        return SearchViewController(
            viewModel: viewModel,
            collectionRepository: dependencyContainer.makeCollectionRepository(),
            tastingRecordRepository: dependencyContainer.makeTastingRecordRepository(),
            localTastingNoteRepository: dependencyContainer.localTastingNoteRepository,
            showsRecentOnAppear: showsRecentOnAppear,
            mode: mode
        )
    }
}
