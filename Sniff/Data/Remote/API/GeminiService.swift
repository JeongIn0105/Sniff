<<<<<<< HEAD
//
//  GeminiService.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//
=======
    //
    //  GeminiService.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.13.
    //
>>>>>>> origin/main

import Foundation
import RxSwift

<<<<<<< HEAD
// MARK: - Input Model
=======
    // MARK: - Input Model
>>>>>>> origin/main
struct TasteAnalysisInput {
    let experience: String
    let vibes: [String]
    let images: [String]
}

<<<<<<< HEAD
// MARK: - Output Model
struct TasteAnalysisResult: Decodable {
    let primaryProfileCode: String
    let primaryProfileName: String
    let secondaryProfileCode: String
    let secondaryProfileName: String
    let analysisSummary: String
    let evidenceTags: EvidenceTags
    let recommendationDirection: RecommendationDirection

    enum CodingKeys: String, CodingKey {
        case primaryProfileCode = "primary_profile_code"
        case primaryProfileName = "primary_profile_name"
        case secondaryProfileCode = "secondary_profile_code"
        case secondaryProfileName = "secondary_profile_name"
        case analysisSummary = "analysis_summary"
        case evidenceTags = "evidence_tags"
        case recommendationDirection = "recommendation_direction"
    }
}

struct EvidenceTags: Decodable {
    let experience: String
    let vibes: [String]
    let images: [String]
}

struct RecommendationDirection: Decodable {
    let preferredImpression: [String]
    let preferredFamilies: [String]
    let intensityLevel: String
    let safeStartingPoint: String

    enum CodingKeys: String, CodingKey {
        case preferredImpression = "preferred_impression"
        case preferredFamilies = "preferred_families"
        case intensityLevel = "intensity_level"
        case safeStartingPoint = "safe_starting_point"
    }
}

// MARK: - Service
=======
    // MARK: - Service
>>>>>>> origin/main
final class GeminiTasteAnalysisService {

    private let apiKey: String
    private let model = "gemini-2.5-flash"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
    }

<<<<<<< HEAD
    // MARK: - RxSwift 기반 취향 분석 호출
=======
    func requestTasteAnalysis(input: TasteAnalysisInput) async throws -> TasteAnalysisResult {
        try await request(input: input)
    }

        // MARK: - RxSwift 기반 취향 분석 호출
>>>>>>> origin/main
    func analyzeTaste(input: TasteAnalysisInput) -> Single<TasteAnalysisResult> {
        Single.create { [weak self] single in
            guard let self else {
                single(.failure(GeminiError.serviceDeallocated))
                return Disposables.create()
            }

            let task = Task {
                do {
                    let result = try await self.request(input: input)
                    single(.success(result))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

<<<<<<< HEAD
    // MARK: - 실제 네트워크 요청
=======
        // MARK: - 실제 네트워크 요청
>>>>>>> origin/main
    private func request(input: TasteAnalysisInput) async throws -> TasteAnalysisResult {
        guard let url = URL(string: baseURL) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONSerialization.data(
            withJSONObject: buildRequestBody(input: input)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let rawText = String(data: data, encoding: .utf8) ?? "응답 본문을 읽을 수 없어요"
            throw GeminiError.httpError(code: httpResponse.statusCode, message: rawText)
        }

        return try parseResponse(data: data)
    }

<<<<<<< HEAD
    // MARK: - 요청 바디 조립
=======
        // MARK: - 요청 바디 조립
>>>>>>> origin/main
    private func buildRequestBody(input: TasteAnalysisInput) -> [String: Any] {
        let vibesString = input.vibes.map { "\"\($0)\"" }.joined(separator: ", ")
        let imagesString = input.images.map { "\"\($0)\"" }.joined(separator: ", ")

        let userInput = """
        {
          "experience": "\(input.experience)",
          "vibes": [\(vibesString)],
          "images": [\(imagesString)]
        }
        """

        return [
            "system_instruction": [
                "parts": [
                    ["text": GeminiPrompts.tasteAnalysis]
                ]
            ],
            "contents": [
                [
                    "parts": [
                        ["text": userInput]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "responseMimeType": "application/json"
            ]
        ]
    }

<<<<<<< HEAD
    // MARK: - 응답 파싱
=======
        // MARK: - 응답 파싱
>>>>>>> origin/main
    private func parseResponse(data: Data) throws -> TasteAnalysisResult {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String,
            let resultData = text.data(using: .utf8)
        else {
            let rawText = String(data: data, encoding: .utf8) ?? "응답 본문을 읽을 수 없어요"
            throw GeminiError.parsingFailed(rawText)
        }

        do {
            return try JSONDecoder().decode(TasteAnalysisResult.self, from: resultData)
        } catch {
            let decodedText = String(data: resultData, encoding: .utf8) ?? "디코딩용 텍스트를 읽을 수 없어요"
            throw GeminiError.decodingFailed(decodedText)
        }
    }
}

<<<<<<< HEAD
// MARK: - Error
=======
    // MARK: - Error
>>>>>>> origin/main
enum GeminiError: Error, LocalizedError {
    case serviceDeallocated
    case invalidURL
    case invalidResponse
    case httpError(code: Int, message: String)
    case parsingFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
<<<<<<< HEAD
        case .serviceDeallocated:
            return "서비스 객체가 해제되었어요"
        case .invalidURL:
            return "잘못된 URL이에요"
        case .invalidResponse:
            return "서버 응답이 올바르지 않아요"
        case .httpError(let code, let message):
            return "서버 응답 오류가 발생했어요. (\(code))\n\(message)"
        case .parsingFailed(let rawText):
            return "결과를 분석하는 데 실패했어요\n\(rawText)"
        case .decodingFailed(let decodedText):
            return "결과 디코딩에 실패했어요\n\(decodedText)"
=======
            case .serviceDeallocated:
                return "서비스 객체가 해제되었어요"
            case .invalidURL:
                return "잘못된 URL이에요"
            case .invalidResponse:
                return "서버 응답이 올바르지 않아요"
            case .httpError(let code, let message):
                return "서버 응답 오류가 발생했어요. (\(code))\n\(message)"
            case .parsingFailed(let rawText):
                return "결과를 분석하는 데 실패했어요\n\(rawText)"
            case .decodingFailed(let decodedText):
                return "결과 디코딩에 실패했어요\n\(decodedText)"
>>>>>>> origin/main
        }
    }
}
