//
//  LocalPerfumeSearchService.swift
//  Sniff
//
//  로컬 향수 검색 서비스
//  Fragella 디스크 캐시 + Firestore 보유/LIKE 향수를 조합하여
//  API 호출 없이 자동완성 후보를 반환합니다.

import Foundation

// MARK: - LocalPerfumeSearchService

final class LocalPerfumeSearchService {

    // MARK: - 내부 인덱스

    /// 중복 제거된 향수 목록 (name + brand 기준)
    private var index: [IndexedEntry] = []
    private let indexLock = NSLock()

    // MARK: - 의존성

    private let firestoreService: FirestoreService
    private let defaults = UserDefaults.standard

    // MARK: - Disk cache 키

    private let searchCacheKey = "sniff.fragella.searchResponses.v1"

    // MARK: - Init

    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
    }

    // MARK: - 인덱스 로드

    /// 앱 시작 후 한 번만 호출 — 디스크 캐시 + Firestore 데이터를 비동기로 인덱싱
    func buildIndex() {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.loadIndex()
        }
    }

    // MARK: - 자동완성 제안

    /// 쿼리에 매칭되는 SuggestionItem 배열을 반환 (동기, 최대 8개)
    func suggestions(for query: String) -> [SuggestionItem] {
        let normalizedQuery = normalizeForSearch(query)
        guard normalizedQuery.count >= 2 else { return [] }

        indexLock.lock()
        let snapshot = index
        indexLock.unlock()

        // 각 항목에 점수 계산 후 정렬
        let scored: [(entry: IndexedEntry, score: Int)] = snapshot.compactMap { entry in
            let score = matchScore(entry: entry, query: normalizedQuery)
            guard score > 0 else { return nil }
            return (entry, score)
        }
        .sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.entry.brand.localizedCaseInsensitiveCompare(rhs.entry.brand) == .orderedAscending
        }

        // 브랜드 제안 (상위 2개)
        var seenBrands = Set<String>()
        var brandItems: [SuggestionItem] = []
        for item in scored {
            let normalizedBrand = normalizeForSearch(item.entry.brand)
            if normalizedBrand.contains(normalizedQuery) && !seenBrands.contains(normalizedBrand) {
                seenBrands.insert(normalizedBrand)
                brandItems.append(.brand(name: item.entry.brand))
                if brandItems.count >= 2 { break }
            }
        }

        // 향수 제안 (상위 6개)
        let perfumeItems: [SuggestionItem] = scored
            .prefix(6)
            .map { .perfume(name: $0.entry.name, brand: $0.entry.brand) }

        // 브랜드 먼저, 향수 뒤 (전체 최대 8개)
        return Array((brandItems + perfumeItems).prefix(8))
    }

    // MARK: - Private: 인덱스 구축

    private func loadIndex() async {
        var entries: [IndexedEntry] = []
        var seenKeys = Set<String>()

        // 1. Fragella 디스크 캐시에서 파싱
        let fragellaPerfumes = loadFragellaCache()
        for p in fragellaPerfumes {
            let key = dedupeKey(name: p.name, brand: p.brand)
            guard seenKeys.insert(key).inserted else { continue }
            entries.append(IndexedEntry(name: p.name, brand: p.brand))
        }

        // 2. Firestore 보유 향수
        if let collection = try? await firestoreService.fetchCollection() {
            for item in collection {
                let key = dedupeKey(name: item.name, brand: item.brand)
                guard seenKeys.insert(key).inserted else { continue }
                entries.append(IndexedEntry(name: item.name, brand: item.brand))
            }
        }

        // 3. Firestore LIKE 향수
        if let liked = try? await firestoreService.fetchLikedPerfumes() {
            for item in liked {
                let key = dedupeKey(name: item.name, brand: item.brand)
                guard seenKeys.insert(key).inserted else { continue }
                entries.append(IndexedEntry(name: item.name, brand: item.brand))
            }
        } 

        await MainActor.run {
            self.index = entries
        }
    }

    private func loadFragellaCache() -> [Perfume] {
        guard
            let data = defaults.data(forKey: searchCacheKey),
            let cacheDict = try? JSONDecoder().decode([String: DiskCacheEntryWrapper].self, from: data)
        else { return [] }

        let now = Date()
        var perfumes: [Perfume] = []
        for (_, entry) in cacheDict {
            // 만료되지 않은 캐시만 사용
            guard !entry.isExpired(referenceDate: now) else { continue }
            if let parsed = try? FragellaResponseParser.parsePerfumeList(from: entry.data) {
                perfumes.append(contentsOf: parsed)
            }
        }
        return perfumes
    }

    // MARK: - Private: 매칭 점수

    private func matchScore(entry: IndexedEntry, query: String) -> Int {
        let name = normalizeForSearch(entry.name)
        let brand = normalizeForSearch(entry.brand)

        if brand == query   { return 1000 }
        if name == query    { return 900 }
        if brand.contains(query) { return 800 }
        if name.contains(query)  { return 700 }
        return 0
    }

    // MARK: - Private: 유틸

    private func normalizeForSearch(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private func dedupeKey(name: String, brand: String) -> String {
        "\(normalizeForSearch(brand))__\(normalizeForSearch(name))"
    }
}

// MARK: - 내부 모델

private struct IndexedEntry {
    let name: String
    let brand: String
}

/// FragellaService 내부의 DiskCacheEntry와 동일한 구조
/// (private 접근제어로 직접 접근 불가하여 별도 정의)
private struct DiskCacheEntryWrapper: Codable {
    let data: Data
    let expiresAt: Date

    func isExpired(referenceDate: Date) -> Bool {
        referenceDate >= expiresAt
    }
}
