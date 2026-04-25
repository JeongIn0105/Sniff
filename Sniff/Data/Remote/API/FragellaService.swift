//
//  FragellaService.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import RxSwift

final class FragellaService {
    static let shared = FragellaService()

    private init() {}

    private let baseURL = "https://api.fragella.com/api/v1"
    private let cacheTTL: TimeInterval = 3_600
    private let diskCacheTTL: TimeInterval = 604_800
    private let defaults = UserDefaults.standard
    private let cacheLock = NSLock()
    private var searchCache: [String: CacheEntry<[Perfume]>] = [:]
    private var detailCache: [String: CacheEntry<Perfume>] = [:]

    func search(query: String, limit: Int = 100) -> Single<[Perfume]> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(FragellaError.invalidURL))
                return Disposables.create()
            }

            let task = Task {
                do {
                    single(.success(try await self.requestSearch(query: query, limit: limit)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func fetchDetail(perfumeId: String) -> Single<Perfume> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(FragellaError.invalidURL))
                return Disposables.create()
            }

            let task = Task {
                do {
                    single(.success(try await self.requestDetail(perfumeId: perfumeId)))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func fetchByFamilies(families: [String], limit: Int = 100) -> Single<[Perfume]> {
        let queries = families.prefix(3).map { family in
            search(query: family, limit: limit)
        }

        return Single.zip(queries)
            .map { results in
                var seen = Set<String>()
                return results.flatMap { $0 }.filter { seen.insert($0.id).inserted }
            }
    }

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

        var request = URLRequest(url: url)
        request.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FragellaError.invalidResponse
        }

        let perfumes = try FragellaResponseParser.parsePerfumeList(from: data)
        storeSearch(perfumes, responseData: data, for: cacheKey)
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

        var request = URLRequest(url: url)
        request.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FragellaError.invalidResponse
        }

        let perfume = try FragellaResponseParser.parsePerfumeDetail(from: data)
        storeDetail(perfume, responseData: data, for: perfumeId)
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

        guard let entry = searchCache[key], !entry.isExpired(referenceDate: Date()) else {
            searchCache[key] = nil
            return cachedDiskSearch(for: key)
        }

        return entry.value
    }

    private func cachedDetail(for key: String) -> Perfume? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        guard let entry = detailCache[key], !entry.isExpired(referenceDate: Date()) else {
            detailCache[key] = nil
            return cachedDiskDetail(for: key)
        }

        return entry.value
    }

    private func storeSearch(_ perfumes: [Perfume], responseData: Data, for key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        searchCache[key] = CacheEntry(value: perfumes, expiresAt: Date().addingTimeInterval(cacheTTL))
        storeDiskResponse(responseData, for: key, storageKey: DiskCacheKey.searchResponses)
    }

    private func storeDetail(_ perfume: Perfume, responseData: Data, for key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        detailCache[key] = CacheEntry(value: perfume, expiresAt: Date().addingTimeInterval(cacheTTL))
        storeDiskResponse(responseData, for: key, storageKey: DiskCacheKey.detailResponses)
    }

    private func cachedDiskSearch(for key: String) -> [Perfume]? {
        guard let data = cachedDiskResponse(for: key, storageKey: DiskCacheKey.searchResponses),
              let perfumes = try? FragellaResponseParser.parsePerfumeList(from: data)
        else {
            removeDiskResponse(for: key, storageKey: DiskCacheKey.searchResponses)
            return nil
        }

        searchCache[key] = CacheEntry(value: perfumes, expiresAt: Date().addingTimeInterval(cacheTTL))
        return perfumes
    }

    private func cachedDiskDetail(for key: String) -> Perfume? {
        guard let data = cachedDiskResponse(for: key, storageKey: DiskCacheKey.detailResponses),
              let perfume = try? FragellaResponseParser.parsePerfumeDetail(from: data)
        else {
            removeDiskResponse(for: key, storageKey: DiskCacheKey.detailResponses)
            return nil
        }

        detailCache[key] = CacheEntry(value: perfume, expiresAt: Date().addingTimeInterval(cacheTTL))
        return perfume
    }

    private func cachedDiskResponse(for key: String, storageKey: String) -> Data? {
        var cache = diskCache(storageKey: storageKey)
        guard let entry = cache[key] else { return nil }

        if entry.isExpired(referenceDate: Date()) {
            cache[key] = nil
            saveDiskCache(cache, storageKey: storageKey)
            return nil
        }

        return entry.data
    }

    private func storeDiskResponse(_ data: Data, for key: String, storageKey: String) {
        var cache = diskCache(storageKey: storageKey)
        cache[key] = DiskCacheEntry(data: data, expiresAt: Date().addingTimeInterval(diskCacheTTL))
        saveDiskCache(cache, storageKey: storageKey)
    }

    private func removeDiskResponse(for key: String, storageKey: String) {
        var cache = diskCache(storageKey: storageKey)
        cache[key] = nil
        saveDiskCache(cache, storageKey: storageKey)
    }

    private func diskCache(storageKey: String) -> [String: DiskCacheEntry] {
        guard let data = defaults.data(forKey: storageKey),
              let cache = try? JSONDecoder().decode([String: DiskCacheEntry].self, from: data)
        else { return [:] }

        return cache
    }

    private func saveDiskCache(_ cache: [String: DiskCacheEntry], storageKey: String) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[FragellaService] \(message)")
        #endif
    }
}

private enum DiskCacheKey {
    static let searchResponses = "sniff.fragella.searchResponses.v1"
    static let detailResponses = "sniff.fragella.detailResponses.v1"
}

private struct CacheEntry<Value> {
    let value: Value
    let expiresAt: Date

    func isExpired(referenceDate: Date) -> Bool {
        referenceDate >= expiresAt
    }
}

private struct DiskCacheEntry: Codable {
    let data: Data
    let expiresAt: Date

    func isExpired(referenceDate: Date) -> Bool {
        referenceDate >= expiresAt
    }
}

enum FragellaError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case invalidDetailIdentifier

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL이에요"
        case .invalidResponse:
            return "서버 응답이 올바르지 않아요"
        case .decodingFailed:
            return "데이터를 불러오는 데 실패했어요"
        case .invalidDetailIdentifier:
            return "상세 조회에 사용할 수 없는 향수 식별자예요"
        }
    }
}
