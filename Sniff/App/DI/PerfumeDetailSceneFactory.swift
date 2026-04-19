//
//  PerfumeDetailSceneFactory.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum PerfumeDetailSceneFactory {

    static func makeViewController(perfume: Perfume) -> PerfumeDetailViewController {
        let repository = PerfumeCatalogRepository()
        let collectionRepository = CollectionRepository()
        let viewModel = PerfumeDetailViewModel(
            perfume: perfume,
            perfumeCatalogRepository: repository
        )
        return PerfumeDetailViewController(
            viewModel: viewModel,
            collectionRepository: collectionRepository
        )
    }

    static func makeViewController(perfumeId: String) -> PerfumeDetailViewController {
        let repository = PerfumeCatalogRepository()
        let collectionRepository = CollectionRepository()
        let viewModel = PerfumeDetailViewModel(
            perfumeId: perfumeId,
            perfumeCatalogRepository: repository
        )
        return PerfumeDetailViewController(
            viewModel: viewModel,
            collectionRepository: collectionRepository
        )
    }
}
