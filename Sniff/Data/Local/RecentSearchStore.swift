//
//  RecentSearchStore.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation
import FirebaseAuth
import RxSwift
import RxRelay

final class RecentSearchStore: RecentSearchStoreType {

    // 계정별로 분리된 UserDefaults 키 (UID 포함)
    private let key: String
    private let maxCount = 10
    private let searchesRelay: BehaviorRelay<[RecentSearch]>

    var searches: Observable<[RecentSearch]> {
        searchesRelay.asObservable()
    }

    /// userID: Firebase Auth의 현재 유저 UID. nil이면 비로그인 상태로 간주해 공유 키 사용.
    init(userID: String?) {
        let resolvedKey: String
        if let uid = userID, !uid.isEmpty {
            resolvedKey = "sniff.recentSearches.\(uid)"
        } else {
            resolvedKey = "sniff.recentSearches.anonymous"
        }
        self.key = resolvedKey
        searchesRelay = BehaviorRelay(value: Self.load(key: resolvedKey))
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

    private static func load(key: String) -> [RecentSearch] {
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
