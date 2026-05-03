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
    /// 자동저장 활성화 여부 (UserDefaults 기반)
    var isAutoSaveEnabled: Bool { get }
    func save(query: String)
    func delete(query: String)
    func clearAll()
    /// 자동저장 켜기/끄기
    func setAutoSaveEnabled(_ enabled: Bool)
}
