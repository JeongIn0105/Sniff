//
//  OnboardingViewModel.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.10.
//

import Foundation
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - 온보딩 단계
    @Published var currentStep: OnboardingStep = .experience

    // MARK: - 유저 선택 데이터
    @Published var selectedExperience: ExperienceLevel? = nil
    @Published var selectedVibes: [String] = []    // 분위기 (최대 3개)
    @Published var selectedImages: [String] = []   // 향의 느낌 (최대 3개)

    // MARK: - Gemini 결과
    @Published var tasteResult: TasteAnalysisResult? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var nickname: String = ""

    // MARK: - 태그 목록
    let vibeTags: [String] = [
        "세련된", "고급스러운", "자연스러운", "활기찬",
        "신비로운", "중성적인", "자신감있는", "여유로운",
        "트렌디한", "신뢰감있는", "품위있는"
    ]

    let imageTags: [String] = [
        "달콤한", "시원한", "따뜻한", "강렬한",
        "은은한", "상큼한", "싱그러운", "묵직한",
        "보송보송한", "무거운", "가벼운"
    ]

    // MARK: - 선택 로직

    func completeOnboarding() {
        // TODO: Firestore 저장 후 홈 탭으로 이동
        currentStep = .experience
    }

    func toggleVibe(_ vibe: String) {
        if selectedVibes.contains(vibe) {
            selectedVibes.removeAll { $0 == vibe }
        } else if selectedVibes.count < 3 {
            selectedVibes.append(vibe)
        }
    }

    func toggleImage(_ image: String) {
        if selectedImages.contains(image) {
            selectedImages.removeAll { $0 == image }
        } else if selectedImages.count < 3 {
            selectedImages.append(image)
        }
    }

    // 다음 버튼 활성화 조건
    var canProceed: Bool {
        !selectedVibes.isEmpty && !selectedImages.isEmpty
    }

    // MARK: - Gemini API 호출

    func analyzeTaste() async {
        guard let experience = selectedExperience else {
            errorMessage = "향수 경험을 먼저 선택해주세요."
            return
        }

        isLoading = true
        errorMessage = nil

        let expText: String
        switch experience {
        case .beginner:
            expText = "향수를 처음 시작했어요"
        case .casual:
            expText = "향수를 가끔씩 뿌려요"
        case .expert:
            expText = "향수를 꽤 알고 있어요"
        }

        let userInput = buildUserInput(expText: expText)

        guard let url = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyAWoB6CkHPFlXZZeOlMC4Z-5ynAOmDB-NI"
        ) else {
            errorMessage = "API URL이 올바르지 않아요."
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
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

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                errorMessage = "서버 응답 오류가 발생했어요. (\(httpResponse.statusCode))"
                isLoading = false
                return
            }

            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let candidates = json["candidates"] as? [[String: Any]],
                let content = candidates.first?["content"] as? [String: Any],
                let parts = content["parts"] as? [[String: Any]],
                let text = parts.first?["text"] as? String,
                let resultData = text.data(using: .utf8)
            else {
                errorMessage = "응답을 해석하지 못했어요."
                isLoading = false
                return
            }

            let result = try JSONDecoder().decode(TasteAnalysisResult.self, from: resultData)
            tasteResult = result
            currentStep = .result

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - 요청용 사용자 입력 JSON 문자열 생성

    private func buildUserInput(expText: String) -> String {
        let vibesText = selectedVibes.map { "\"\($0)\"" }.joined(separator: ", ")
        let imagesText = selectedImages.map { "\"\($0)\"" }.joined(separator: ", ")

        return """
        {
          "experience": "\(expText)",
          "vibes": [\(vibesText)],
          "images": [\(imagesText)]
        }
        """
    }
}

// MARK: - Enums

enum OnboardingStep {
    case experience
    case taste
    case result
}

enum ExperienceLevel: String {
    case beginner = "beginner"
    case casual = "casual"
    case expert = "expert"
}
