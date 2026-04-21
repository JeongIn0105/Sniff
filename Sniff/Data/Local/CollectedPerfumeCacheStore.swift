//
//  CollectedPerfumeCacheStore.swift
//  Sniff
//
//  Created by Codex on 2026.04.21.
//

import Foundation

final class CollectedPerfumeCacheStore {
    private let key = "sniff.collectedPerfumes.cache"

    func load() -> [CollectedPerfume] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([CachedCollectedPerfume].self, from: data)
        else {
            return []
        }

        return decoded.map(\.model)
    }

    func save(_ perfumes: [CollectedPerfume]) {
        let payload = perfumes.map(CachedCollectedPerfume.init)
        guard let encoded = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    func upsert(_ perfume: CollectedPerfume) {
        var current = load()
        current.removeAll { $0.id == perfume.id }
        current.insert(perfume, at: 0)
        save(current)
    }

    func delete(id: String) {
        var current = load()
        current.removeAll { $0.id == id }
        save(current)
    }
}

private struct CachedCollectedPerfume: Codable {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let mainAccords: [String]
    let accordStrengths: [String: String]
    let memo: String?
    let createdAt: Date?

    init(_ perfume: CollectedPerfume) {
        id = perfume.id
        name = perfume.name
        brand = perfume.brand
        imageUrl = perfume.imageUrl
        mainAccords = perfume.mainAccords
        accordStrengths = perfume.accordStrengths.mapValues(\.rawValue)
        memo = perfume.memo
        createdAt = perfume.createdAt
    }

    var model: CollectedPerfume {
        CollectedPerfume(
            id: id,
            name: name,
            brand: brand,
            imageUrl: imageUrl,
            mainAccords: mainAccords,
            accordStrengths: accordStrengths.reduce(into: [String: AccordStrength]()) { result, pair in
                guard let strength = AccordStrength(rawDescription: pair.value) else { return }
                result[pair.key] = strength
            },
            memo: memo,
            createdAt: createdAt
        )
    }
}
