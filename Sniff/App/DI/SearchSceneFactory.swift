//
//  SearchSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum SearchSceneFactory {

    static func makeSearchViewController() -> SearchViewController {
        let repository = PerfumeCatalogRepository()
        let searchPerfumesUseCase = SearchPerfumesUseCase(repository: repository)
        let viewModel = SearchViewModel(
            searchPerfumesUseCase: searchPerfumesUseCase,
            recentSearchStore: RecentSearchStore()
        )
        return SearchViewController(viewModel: viewModel)
    }
}
