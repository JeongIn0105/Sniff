//
//  PerfumeNameTranslationService.swift
//  Sniff
//
//  Created by 이정인 on 2026.04.16.
//

import Foundation

// MARK: - 향수명 한국어 음역 번역 서비스 (Gemini 기반)
// 영문 향수명을 한국어 발음 표기로 변환합니다.
// - 결과는 앱 세션 동안 메모리에 캐시됩니다 (중복 API 호출 방지).
// - Gemini API 키가 없거나 오류 발생 시 영문명을 그대로 사용합니다.

enum PerfumeNameTranslationService {

    // MARK: - 세션 캐시 (영문명 → 한국어 음역)

    private static var cache: [String: String] = [:]

    // MARK: - 번역 요청

    /// 여러 향수명을 한 번의 Gemini 호출로 일괄 번역합니다.
    /// - Parameter names: 번역할 영문 향수명 배열
    /// - Returns: [영문명: 한국어 음역] 딕셔너리 (캐시 포함)
    static func translate(names: [String]) async throws -> [String: String] {
        // 캐시에 없는 것만 Gemini로 번역
        let uncached = names.filter { cache[$0] == nil }

        if !uncached.isEmpty {
            let apiKey = try AppSecrets.geminiAPIKey()
            let translated = try await callGemini(names: uncached, apiKey: apiKey)
            for (name, korean) in translated {
                cache[name] = korean
            }
        }

        // 캐시에서 결과 조합
        return Dictionary(
            names.compactMap { name in cache[name].map { (name, $0) } },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // MARK: - Gemini API 호출

    private static func callGemini(names: [String], apiKey: String) async throws -> [String: String] {
        let model = "gemini-2.5-flash"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else { throw TranslationError.invalidURL }

        // 번호 붙인 향수명 목록
        let nameList = names.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")

        let prompt = """
        아래 향수 이름들을 한국어 발음 표기(음역)로 변환해줘.
        브랜드명은 번역하지 말고, 향수 고유명사도 발음 그대로 음역해줘.
        입력과 동일한 순서로 JSON 문자열 배열로만 응답해. 설명 없이 JSON만.

        예시:
        입력 → ["Jo Malone Variety", "Creed Aventus", "Byredo Bal d'Afrique"]
        출력 → ["조 말론 버라이어티", "크리드 어벤투스", "바이레도 발 다프리크"]

        번역할 목록:
        \(nameList)
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": 0.1,
                "responseMimeType": "application/json"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw TranslationError.apiError
        }

        // Gemini 응답 파싱
        guard
            let json        = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates  = json["candidates"] as? [[String: Any]],
            let content     = candidates.first?["content"] as? [String: Any],
            let parts       = content["parts"] as? [[String: Any]],
            let text        = parts.first?["text"] as? String,
            let arrayData   = text.data(using: .utf8),
            let koreanNames = try? JSONSerialization.jsonObject(with: arrayData) as? [String]
        else {
            throw TranslationError.parsingFailed
        }

        // 영문명 ↔ 한국어명 매핑
        var result: [String: String] = [:]
        for (i, name) in names.enumerated() where i < koreanNames.count {
            let korean = koreanNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if !korean.isEmpty { result[name] = korean }
        }
        return result
    }

    // MARK: - 에러

    enum TranslationError: Error {
        case invalidURL
        case apiError
        case parsingFailed
    }
}
