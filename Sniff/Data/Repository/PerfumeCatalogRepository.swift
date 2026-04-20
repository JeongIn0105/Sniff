//
//  PerfumeCatalogRepository.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

final class PerfumeCatalogRepository: PerfumeCatalogRepositoryType {

    private let remoteService: FragellaService

    init(remoteService: FragellaService = .shared) {
        self.remoteService = remoteService
    }

    func search(query: String, limit: Int) -> Single<[Perfume]> {
        remoteService.search(query: query, limit: limit)
    }

    func fetchDetail(perfumeId: String) -> Single<Perfume> {
        remoteService.fetchDetail(perfumeId: perfumeId)
    }

    func fetchByFamilies(families: [String], limit: Int) -> Single<[Perfume]> {
        remoteService.fetchByFamilies(families: families, limit: limit)
    }
}
