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

    // MARK: - Properties

    /// 계정별로 분리된 최근 검색어 UserDefaults 키
    private let key: String
    /// 계정별로 분리된 자동저장 설정 UserDefaults 키
    private let autoSaveKey: String
    private let maxCount = 10
    private let searchesRelay: BehaviorRelay<[RecentSearch]>

    var searches: Observable<[RecentSearch]> {
        searchesRelay.asObservable()
    }

    /// 자동저장 활성화 여부 — 기본값 true (최초 진입 시 켜짐 상태)
    var isAutoSaveEnabled: Bool {
        UserDefaults.standard.object(forKey: autoSaveKey) as? Bool ?? true
    }

    // MARK: - Init

    /// userID: Firebase Auth의 현재 유저 UID. nil이면 비로그인 상태로 간주해 공유 키 사용.
    init(userID: String?) {
        let suffix: String
        if let uid = userID, !uid.isEmpty {
            suffix = uid
        } else {
            suffix = "anonymous"
        }
        self.key = "sniff.recentSearches.\(suffix)"
        self.autoSaveKey = "sniff.autoSave.\(suffix)"
        searchesRelay = BehaviorRelay(value: Self.load(key: "sniff.recentSearches.\(suffix)"))
    }

    // MARK: - RecentSearchStoreType

    func setAutoSaveEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: autoSaveKey)
    }

    func save(query: String) {
        // 자동저장이 꺼져 있으면 아무것도 하지 않음
        guard isAutoSaveEnabled else { return }

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

    // MARK: - Private Helpers

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
