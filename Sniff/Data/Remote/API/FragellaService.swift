//
//  File.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import RxSwift

    // MARK: - Response Model
struct FragellaSearchResponse: Decodable {
    let data: [FragellaPerfume]
}

struct FragellaPerfume: Decodable {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let scentFamily: String?
    let scentFamily2: String?
    let topNotes: [String]?
    let middleNotes: [String]?
    let baseNotes: [String]?
    let concentration: String?
    let gender: String?
    let season: [String]?
    let situation: [String]?
    let longevity: String?
    let sillage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case imageUrl = "image_url"
        case scentFamily = "scent_family"
        case scentFamily2 = "scent_family2"
        case topNotes = "top_notes"
        case middleNotes = "middle_notes"
        case baseNotes = "base_notes"
        case concentration
        case gender
        case season
        case situation
        case longevity
        case sillage
    }
}

    // MARK: - Service
final class FragellaService {

    static let shared = FragellaService()
    private init() {}

    private let apiKey = "0e4d3ff3231b3243fa544f797311c0df9175c3ce946c3df588365a70f76961e3" // ⚠️ 실제 키로 교체
    private let baseURL = "https://api.fragella.com/api/v1"

        // MARK: - 향수 검색
    func search(query: String, limit: Int = 20) -> Single<[FragellaPerfume]> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(FragellaError.invalidURL))
                return Disposables.create()
            }

            Task {
                do {
                    let result = try await self.requestSearch(
                        query: query,
                        limit: limit
                    )
                    single(.success(result))
                } catch {
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

        // MARK: - 향수 상세 조회
    func fetchDetail(perfumeId: String) -> Single<FragellaPerfume> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(FragellaError.invalidURL))
                return Disposables.create()
            }

            Task {
                do {
                    let result = try await self.requestDetail(
                        perfumeId: perfumeId
                    )
                    single(.success(result))
                } catch {
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }

        // MARK: - 실제 네트워크 요청 (검색)
    private func requestSearch(
        query: String,
        limit: Int
    ) async throws -> [FragellaPerfume] {
        let encodedQuery = query.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? query

        let urlString = "\(baseURL)/fragrances?search=\(encodedQuery)&limit=\(limit)"

        guard let url = URL(string: urlString) else {
            throw FragellaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FragellaError.invalidResponse
        }

        let result = try JSONDecoder().decode(
            FragellaSearchResponse.self,
            from: data
        )
        return result.data
    }

        // MARK: - 실제 네트워크 요청 (상세)
    private func requestDetail(
        perfumeId: String
    ) async throws -> FragellaPerfume {
        let urlString = "\(baseURL)/fragrances/\(perfumeId)"

        guard let url = URL(string: urlString) else {
            throw FragellaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FragellaError.invalidResponse
        }

        return try JSONDecoder().decode(FragellaPerfume.self, from: data)
    }
}

    // MARK: - Error
enum FragellaError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
            case .invalidURL: return "잘못된 URL이에요"
            case .invalidResponse: return "서버 응답이 올바르지 않아요"
            case .decodingFailed: return "데이터를 불러오는 데 실패했어요"
        }
    }
}
