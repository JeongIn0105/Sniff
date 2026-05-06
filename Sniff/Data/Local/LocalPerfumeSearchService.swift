//
//  LocalPerfumeSearchService.swift
//  Sniff
//
//  로컬 향수 검색 서비스
//  Firestore 보유/LIKE 향수를 조합하여 자동완성 후보를 반환합니다.

import Foundation

// MARK: - LocalPerfumeSearchService

final class LocalPerfumeSearchService {

    // MARK: - 내부 인덱스

    /// 중복 제거된 향수 목록 (name + brand 기준)
    private var index: [IndexedEntry] = []
    private let indexLock = NSLock()

    // MARK: - 의존성

    private let firestoreService: FirestoreService
    // MARK: - Init

    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
    }

    // MARK: - 인덱스 로드

    /// 앱 시작 후 한 번만 호출 — Firestore 데이터를 비동기로 인덱싱
    func buildIndex(includesUserData: Bool = true) {
        Task(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.loadIndex(includesUserData: includesUserData)
        }
    }

    // MARK: - 자동완성 제안

    /// 쿼리에 매칭되는 SuggestionItem 배열을 반환 (동기, 최대 8개)
    func suggestions(for query: String) -> [SuggestionItem] {
        let normalizedQueries = searchQueryCandidates(for: query)
        guard !normalizedQueries.isEmpty else { return [] }

        indexLock.lock()
        let snapshot = index
        indexLock.unlock()

        // 각 항목에 점수 계산 후 정렬
        let scored: [(entry: IndexedEntry, score: Int)] = snapshot.compactMap { entry in
            let score = normalizedQueries
                .map { matchScore(entry: entry, query: $0) }
                .max() ?? 0
            guard score > 0 else { return nil }
            return (entry, score)
        }
        .sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.entry.brand.localizedCaseInsensitiveCompare(rhs.entry.brand) == .orderedAscending
        }

        // 브랜드 제안 (상위 2개) — 브랜드의 대표 이미지는 해당 브랜드 첫 번째 향수 이미지 사용
        var seenBrands = Set<String>()
        var brandItems: [SuggestionItem] = []
        for item in scored {
            if normalizedQueries.contains(where: { brandMatchScore(entry: item.entry, query: $0) >= 600 }),
               !seenBrands.contains(item.entry.dedupeBrandKey) {
                seenBrands.insert(item.entry.dedupeBrandKey)
                brandItems.append(.brand(name: item.entry.brand, imageUrl: item.entry.imageUrl))
                if brandItems.count >= 2 { break }
            }
        }

        // 향수 제안 (상위 6개)
        let perfumeItems: [SuggestionItem] = scored
            .prefix(6)
            .map { .perfume(name: $0.entry.name, brand: $0.entry.brand, imageUrl: $0.entry.imageUrl) }

        // 브랜드 먼저, 향수 뒤 (전체 최대 8개)
        return Array((brandItems + perfumeItems).prefix(8))
    }

    // MARK: - Private: 인덱스 구축

    private func loadIndex(includesUserData: Bool) async {
        var entries: [IndexedEntry] = []
        var seenKeys = Set<String>()

        if includesUserData {
            // 1. Firestore 보유 향수
            if let collection = try? await firestoreService.fetchCollection() {
                for item in collection {
                    let key = dedupeKey(name: item.name, brand: item.brand)
                    guard seenKeys.insert(key).inserted else { continue }
                    entries.append(makeIndexedEntry(name: item.name, brand: item.brand, imageUrl: item.imageUrl))
                }
            }

            // 2. Firestore LIKE 향수 (LikedPerfume 모델은 imageURL — 대문자)
            if let liked = try? await firestoreService.fetchLikedPerfumes() {
                for item in liked {
                    let key = dedupeKey(name: item.name, brand: item.brand)
                    guard seenKeys.insert(key).inserted else { continue }
                    entries.append(makeIndexedEntry(name: item.name, brand: item.brand, imageUrl: item.imageURL))
                }
            }
        }

        replaceIndex(entries)
    }

    // MARK: - Private: 매칭 점수

    private func matchScore(entry: IndexedEntry, query: String) -> Int {
        max(
            brandMatchScore(entry: entry, query: query),
            nameMatchScore(entry: entry, query: query)
        )
    }

    private func brandMatchScore(entry: IndexedEntry, query: String) -> Int {
        if entry.normalizedSearchableBrands.contains(query) { return 1000 }
        if entry.normalizedSearchableBrands.contains(where: { $0.contains(query) }) { return 800 }
        if query.count >= 4,
           entry.normalizedSearchableBrands.contains(where: { isNearTypo($0, query) }) {
            return 650
        }
        return 0
    }

    private func nameMatchScore(entry: IndexedEntry, query: String) -> Int {
        if entry.normalizedSearchableNames.contains(query) { return 900 }
        if entry.normalizedSearchableNames.contains(where: { $0.contains(query) }) { return 700 }
        if query.count >= 4,
           entry.normalizedSearchableNames.contains(where: { isNearTypo($0, query) }) {
            return 600
        }
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

    private func searchQueryCandidates(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [trimmed, PerfumeKoreanTranslator.toEnglishQuery(trimmed)]
            .compactMap { $0 }
            .map(normalizeForSearch(_:))
            .filter { $0.count >= 2 }

        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    private func dedupeKey(name: String, brand: String) -> String {
        "\(normalizeForSearch(brand))__\(normalizeForSearch(name))"
    }

    private func isNearTypo(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs.count >= 2, rhs.count >= 2 else { return false }
        let lengthGap = abs(lhs.count - rhs.count)
        guard lengthGap <= 1 else { return false }

        if lhs.count <= 5 || rhs.count <= 5 {
            return editDistance(lhs, rhs, maxDistance: 1) <= 1
        }
        return editDistance(lhs, rhs, maxDistance: 2) <= 2
    }

    private func editDistance(_ lhs: String, _ rhs: String, maxDistance: Int) -> Int {
        let lhs = Array(lhs)
        let rhs = Array(rhs)
        if abs(lhs.count - rhs.count) > maxDistance { return maxDistance + 1 }
        if lhs.isEmpty { return rhs.count }
        if rhs.isEmpty { return lhs.count }

        var previous = Array(0...rhs.count)
        for i in 1...lhs.count {
            var current = [i] + Array(repeating: 0, count: rhs.count)
            var rowMinimum = current[0]
            for j in 1...rhs.count {
                let cost = lhs[i - 1] == rhs[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
                rowMinimum = min(rowMinimum, current[j])
            }
            if rowMinimum > maxDistance { return maxDistance + 1 }
            previous = current
        }
        return previous[rhs.count]
    }

    private func makeIndexedEntry(name: String, brand: String, imageUrl: String? = nil) -> IndexedEntry {
        let searchableNames = uniqueSearchValues([
            name,
            PerfumePresentationSupport.displayPerfumeName(name)
        ])
        let searchableBrands = uniqueSearchValues([
            brand,
            PerfumePresentationSupport.displayBrand(brand)
        ])

        return IndexedEntry(
            name: name,
            brand: brand,
            searchableNames: searchableNames,
            searchableBrands: searchableBrands,
            normalizedSearchableNames: searchableNames.map(normalizeForSearch(_:)),
            normalizedSearchableBrands: searchableBrands.map(normalizeForSearch(_:)),
            imageUrl: imageUrl
        )
    }

    private func uniqueSearchValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert(normalizeForSearch($0)).inserted }
    }

    private func replaceIndex(_ entries: [IndexedEntry]) {
        indexLock.lock()
        index = entries
        indexLock.unlock()
    }
}

// MARK: - 내부 모델

private struct IndexedEntry {
    let name: String
    let brand: String
    let searchableNames: [String]
    let searchableBrands: [String]
    let normalizedSearchableNames: [String]
    let normalizedSearchableBrands: [String]
    /// 썸네일 이미지 URL (연관 검색어 셀 표시용)
    let imageUrl: String?

    var dedupeBrandKey: String {
        brand.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
