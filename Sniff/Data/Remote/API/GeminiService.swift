//
//  GeminiService.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Foundation
import RxSwift

final class GeminiTasteAnalysisService {

    private let apiKey: String
    private let model = "gemini-2.5-flash"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
    }

    func requestTasteAnalysis(input: TasteAnalysisInput) async throws -> TasteAnalysisResult {
        try await request(input: input)
    }

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

    private func buildRequestBody(input: TasteAnalysisInput) -> [String: Any] {
        [
            "system_instruction": [
                "parts": [
                    ["text": GeminiPrompts.tasteAnalysis]
                ]
            ],
            "contents": [
                [
                    "parts": [
                        ["text": makePromptInput(from: input)]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "responseMimeType": "application/json"
            ]
        ]
    }

    private func makePromptInput(from input: TasteAnalysisInput) -> String {
        var sections: [String] = [
            makeJSONSection(
                title: "Onboarding Signal (JSON)",
                value: OnboardingSignalForGemini(
                    experience: input.experience,
                    vibes: input.vibes,
                    images: input.images
                )
            )
        ]

        if let aggregatedProfile = input.aggregatedProfile {
            sections.append(
                makeJSONSection(
                    title: "Aggregated Preference Profile",
                    preface: "Use this as the primary signal for taste analysis.",
                    value: aggregatedProfile
                )
            )
        }

        if !input.records.isEmpty {
            sections.append(
                makeJSONSection(
                    title: "Tasting Records (JSON)",
                    preface: """
                    Analyze ONLY the structured data below. Do not infer from field names.
                    Use the structured records below only as supporting evidence.
                    Prioritize repeated patterns across accords, mood tags, and revisit desire.
                    Do not invent preferences that are not supported by the records.
                    """,
                    value: input.records
                )
            )
        }

        return sections.joined(separator: "\n\n")
    }

    private func makeJSONSection<T: Encodable>(
        title: String,
        preface: String? = nil,
        value: T
    ) -> String {
        var lines = ["## \(title)"]
        if let preface {
            lines.append(preface)
        }
        lines.append(encodedJSONString(from: value))
        return lines.joined(separator: "\n")
    }

    private func encodedJSONString<T: Encodable>(from value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        guard
            let data = try? encoder.encode(value),
            let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return json
    }

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

private struct OnboardingSignalForGemini: Encodable {
    let experience: String
    let vibes: [String]
    let images: [String]
}

enum GeminiError: Error, LocalizedError {
    case serviceDeallocated
    case invalidURL
    case invalidResponse
    case httpError(code: Int, message: String)
    case parsingFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
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
        }
    }
}
