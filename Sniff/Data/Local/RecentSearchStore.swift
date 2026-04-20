//
//  RecentSearchStore.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import RxSwift
import RxRelay

final class RecentSearchStore: RecentSearchStoreType {

    private let key = "sniff.recentSearches"
    private let maxCount = 10
    private let searchesRelay: BehaviorRelay<[RecentSearch]>

    var searches: Observable<[RecentSearch]> {
        searchesRelay.asObservable()
    }

    init() {
        searchesRelay = BehaviorRelay(value: Self.load())
    }

    func save(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        var current = searchesRelay.value
        current.removeAll { $0.query == trimmed }
        current.insert(RecentSearch(query: trimmed), at: 0)

        if current.count > maxCount {
            current = Array(current.prefix(maxCount))
        }

        searchesRelay.accept(current)
        Self.save(searches: current, key: key)
    }

    func delete(query: String) {
        var current = searchesRelay.value
        current.removeAll { $0.query == query }
        searchesRelay.accept(current)
        Self.save(searches: current, key: key)
    }

    func clearAll() {
        searchesRelay.accept([])
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func load(key: String = "sniff.recentSearches") -> [RecentSearch] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data)
        else {
            return []
        }
        return decoded
    }

    private static func save(searches: [RecentSearch], key: String) {
        guard let encoded = try? JSONEncoder().encode(searches) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }
}
