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
}
