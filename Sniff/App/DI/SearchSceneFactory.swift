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
        let viewModel = SearchViewModel(
            perfumeCatalogRepository: repository,
            recentSearchStore: RecentSearchStore()
        )
        return SearchViewController(
            viewModel: viewModel,
            collectionRepository: CollectionRepository()
        )
    }
}
