//
//  FragellaService.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import RxSwift

// MARK: - AccordStrength

enum AccordStrength: String {
    case dominant
    case prominent
    case moderate
    case subtle

    init?(rawDescription: String) {
        switch rawDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "dominant":  self = .dominant
        case "prominent": self = .prominent
        case "moderate":  self = .moderate
        case "subtle":    self = .subtle
        default:          return nil
        }
    }

    var weight: Double {
        switch self {
        case .dominant:  return 1.0
        case .prominent: return 0.8
        case .moderate:  return 0.55
        case .subtle:    return 0.3
        }
    }
}

// MARK: - FragellaPerfume

struct FragellaPerfume {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let mainAccords: [String]
    let mainAccordStrengths: [String: AccordStrength]
    let topNotes: [String]?
    let middleNotes: [String]?
    let baseNotes: [String]?
    let concentration: String?
    let gender: String?
    let season: [String]?
    let situation: [String]?
    let longevity: String?
    let sillage: String?

    init(
        id: String,
        name: String,
        brand: String,
        imageUrl: String?,
        mainAccords: [String],
        mainAccordStrengths: [String: AccordStrength] = [:],
        topNotes: [String]?,
        middleNotes: [String]?,
        baseNotes: [String]?,
        concentration: String?,
        gender: String?,
        season: [String]?,
        situation: [String]?,
        longevity: String?,
        sillage: String?
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.imageUrl = Self.normalizeImageURL(imageUrl)

        let canonicalMainAccords = ScentFamilyNormalizer.canonicalNames(for: mainAccords)
        self.mainAccords = canonicalMainAccords
        self.mainAccordStrengths = Self.normalizeAccordStrengths(
            from: mainAccordStrengths,
            orderedMainAccords: canonicalMainAccords
        )
        self.topNotes = topNotes
        self.middleNotes = middleNotes
        self.baseNotes = baseNotes
        self.concentration = concentration
        self.gender = gender
        self.season = season
        self.situation = situation
        self.longevity = longevity
        self.sillage = sillage
    }

    // MARK: - 이미지 URL 정규화 (http → https 변환 등)
    private static func normalizeImageURL(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("//") {
            return "https:\(trimmed)"
        } else if trimmed.hasPrefix("http://") {
            return "https://" + trimmed.dropFirst("http://".count)
        } else {
            return trimmed
        }
    }

    // MARK: - Accord Strength 정규화 (rawStrengths에 없는 accord는 순서 기반 fallback 적용)
    private static func normalizeAccordStrengths(
        from rawStrengths: [String: AccordStrength],
        orderedMainAccords: [String]
    ) -> [String: AccordStrength] {
        var normalized: [String: AccordStrength] = [:]
        for (rawAccord, strength) in rawStrengths {
            guard let canonical = ScentFamilyNormalizer.canonicalName(for: rawAccord) else { continue }
            let existing = normalized[canonical]?.weight ?? -1
            if strength.weight > existing {
                normalized[canonical] = strength
            }
        }
        let fallbackStrengths: [AccordStrength] = [.dominant, .prominent, .moderate, .subtle]
        for (index, accord) in orderedMainAccords.enumerated() {
            guard normalized[accord] == nil else { continue }
            normalized[accord] = index < fallbackStrengths.count ? fallbackStrengths[index] : .subtle
        }
        return normalized
    }
}

// MARK: - FragellaService

final class FragellaService {
    static let shared = FragellaService()
    private init() {}

    private let baseURL = "https://api.fragella.com/api/v1"
    private let cacheTTL: TimeInterval = 300
    private let cacheLock = NSLock()
    private var searchCache: [String: CacheEntry<[Perfume]>] = [:]
    private var detailCache: [String: CacheEntry<Perfume>] = [:]

    // MARK: - Public API

    func search(query: String, limit: Int = 20) -> Single<[Perfume]> {
        Single.create { [weak self] single in
            guard let self else { single(.failure(FragellaError.invalidURL)); return Disposables.create() }
            Task {
                do { single(.success(try await self.requestSearch(query: query, limit: limit))) }
                catch { single(.failure(error)) }
            }
            return Disposables.create()
        }
    }

    func fetchDetail(perfumeId: String) -> Single<Perfume> {
        Single.create { [weak self] single in
            guard let self else { single(.failure(FragellaError.invalidURL)); return Disposables.create() }
            Task {
                do { single(.success(try await self.requestDetail(perfumeId: perfumeId))) }
                catch { single(.failure(error)) }
            }
            return Disposables.create()
        }
    }

    func fetchByFamilies(families: [String], limit: Int = 20) -> Single<[Perfume]> {
        let queries = families.prefix(3).map { family in
            search(query: family, limit: limit)
        }
        return Single.zip(queries)
            .map { results in
                var seen = Set<String>()
                return results.flatMap { $0 }.filter { seen.insert($0.id).inserted }
            }
    }

    // MARK: - Private

    private func requestSearch(query: String, limit: Int) async throws -> [Perfume] {
        let cacheKey = makeSearchCacheKey(query: query, limit: limit)
        if let cached = cachedSearch(for: cacheKey) {
            log("CACHE HIT search query=\"\(query)\" limit=\(limit) count=\(cached.count)")
            return cached
        }
        log("REQUEST search query=\"\(query)\" limit=\(limit)")
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "\(baseURL)/fragrances?search=\(encoded)&limit=\(limit)") else {
            throw FragellaError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FragellaError.invalidResponse
        }
        let perfumes = try FragellaResponseParser.parsePerfumeList(from: data)
        storeSearch(perfumes, for: cacheKey)
        log("RESPONSE search query=\"\(query)\" limit=\(limit) count=\(perfumes.count)")
        return perfumes
    }

    private func requestDetail(perfumeId: String) async throws -> Perfume {
        if let cached = cachedDetail(for: perfumeId) {
            log("CACHE HIT detail perfumeId=\(perfumeId)")
            return cached
        }
        log("REQUEST detail perfumeId=\(perfumeId)")
        guard let url = URL(string: "\(baseURL)/fragrances/\(perfumeId)") else {
            throw FragellaError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FragellaError.invalidResponse
        }
        let perfume = try FragellaResponseParser.parsePerfumeDetail(from: data)
        storeDetail(perfume, for: perfumeId)
        log("RESPONSE detail perfumeId=\(perfumeId) name=\"\(perfume.name)\"")
        return perfume
    }

    private func apiKey() throws -> String {
        try AppSecrets.fragellaAPIKey()
    }

    private func makeSearchCacheKey(query: String, limit: Int) -> String {
        "\(query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())::\(limit)"
    }

    private func cachedSearch(for key: String) -> [Perfume]? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        guard let entry = searchCache[key], !entry.isExpired(referenceDate: Date()) else {
            searchCache[key] = nil; return nil
        }
        return entry.value
    }

    private func cachedDetail(for key: String) -> Perfume? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        guard let entry = detailCache[key], !entry.isExpired(referenceDate: Date()) else {
            detailCache[key] = nil; return nil
        }
        return entry.value
    }

    private func storeSearch(_ perfumes: [Perfume], for key: String) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        searchCache[key] = CacheEntry(value: perfumes, expiresAt: Date().addingTimeInterval(cacheTTL))
    }

    private func storeDetail(_ perfume: Perfume, for key: String) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        detailCache[key] = CacheEntry(value: perfume, expiresAt: Date().addingTimeInterval(cacheTTL))
    }

    private func log(_ message: String) {
        print("[FragellaService] \(message)")
    }
}

// MARK: - CacheEntry

private struct CacheEntry<Value> {
    let value: Value
    let expiresAt: Date

    func isExpired(referenceDate: Date) -> Bool {
        referenceDate >= expiresAt
    }
}

// MARK: - FragellaError

enum FragellaError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case invalidDetailIdentifier

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "잘못된 URL이에요"
        case .invalidResponse:         return "서버 응답이 올바르지 않아요"
        case .decodingFailed:          return "데이터를 불러오는 데 실패했어요"
        case .invalidDetailIdentifier: return "상세 조회에 사용할 수 없는 향수 식별자예요"
        }
    }
}