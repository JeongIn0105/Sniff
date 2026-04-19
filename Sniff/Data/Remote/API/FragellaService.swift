    //
    //  FragellaService.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.13.
    //


import Foundation
import RxSwift

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

        // MARK: - 추천용 향수 조회 (계열 기반)
        // 취향 벡터의 상위 계열들로 Fragella를 쿼리하는 핵심 메서드
    func fetchByFamilies(families: [String], limit: Int = 20) -> Single<[Perfume]> {
            // Fragella는 단일 쿼리만 지원 → 상위 계열로 순차 검색 후 병합
        let queries = families.prefix(3).map { family in
            search(query: family, limit: limit)
        }

        return Single.zip(queries)
            .map { results in
                    // 중복 제거 (id 기준) + 상위 limit개 반환
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
        cacheLock.lock()
        defer { cacheLock.unlock() }

        guard let entry = searchCache[key] else { return nil }
        guard !entry.isExpired(referenceDate: Date()) else {
            searchCache[key] = nil
            return nil
        }
        return entry.value
    }

    private func cachedDetail(for key: String) -> Perfume? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        guard let entry = detailCache[key] else { return nil }
        guard !entry.isExpired(referenceDate: Date()) else {
            detailCache[key] = nil
            return nil
        }
        return entry.value
    }

    private func storeSearch(_ perfumes: [Perfume], for key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        searchCache[key] = CacheEntry(value: perfumes, expiresAt: Date().addingTimeInterval(cacheTTL))
    }

    private func storeDetail(_ perfume: Perfume, for key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        detailCache[key] = CacheEntry(value: perfume, expiresAt: Date().addingTimeInterval(cacheTTL))
    }

    private func log(_ message: String) {
        print("[FragellaService] \(message)")
    }
}

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

    var errorDescription: String? {
        switch self {
            case .invalidURL:      return "잘못된 URL이에요"
            case .invalidResponse: return "서버 응답이 올바르지 않아요"
            case .decodingFailed:  return "데이터를 불러오는 데 실패했어요"
        }
    }
}
