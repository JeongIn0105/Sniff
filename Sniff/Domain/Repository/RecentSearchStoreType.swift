//
//  RecentSearchStoreType.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift

protocol RecentSearchStoreType {
    var searches: Observable<[RecentSearch]> { get }
    func save(query: String)
    func delete(query: String)
    func clearAll()
}
