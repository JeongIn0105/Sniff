//
//  PerfumeCatalogRepositoryType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol PerfumeCatalogRepositoryType {
    func search(query: String, limit: Int) -> Single<[Perfume]>
    func fetchDetail(perfumeId: String) -> Single<Perfume>
    func fetchByFamilies(families: [String], limit: Int) -> Single<[Perfume]>
}
