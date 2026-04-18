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
        return try FragellaResponseParser.parsePerfumeList(from: data)
    }

    private func requestDetail(perfumeId: String) async throws -> Perfume {
        guard let url = URL(string: "\(baseURL)/fragrances/\(perfumeId)") else {
            throw FragellaError.invalidURL
        }
        var req = URLRequest(url: url)
        req.setValue(try apiKey(), forHTTPHeaderField: "x-api-key")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw FragellaError.invalidResponse
        }
        return try FragellaResponseParser.parsePerfumeDetail(from: data)
    }

    private func apiKey() throws -> String {
        try AppSecrets.fragellaAPIKey()
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
