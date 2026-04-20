//
//  CollectionRepositoryType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol CollectionRepositoryType {
    func fetchCollection() -> Single<[CollectedPerfume]>
    func saveCollectedPerfume(_ perfume: Perfume, memo: String?) -> Completable
    func deleteCollectedPerfume(id: String) -> Completable
}
