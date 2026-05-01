//
//  SubFamilyClassifier.swift
//  Sniff
//
//  Created by OpenAI Codex on 2026.04.29.
//

import Foundation
import RxCocoa
import RxSwift

nonisolated enum MainScentFamily: String, CaseIterable, Codable {
    case floral = "플로럴"
    case fresh = "프레쉬"
    case woody = "우디"
    case amber = "앰버"

    var canonicalName: String {
        switch self {
        case .floral: return "Floral"
        case .fresh: return "Fresh"
        case .woody: return "Woody"
        case .amber: return "Amber"
        }
    }
}

nonisolated enum SubFamily: String, CaseIterable, Codable {
    case citrus = "시트러스"
    case water = "워터"
    case green = "그린"
    case fruity = "프루티"
    case aromatic = "아로마틱"
    case floral = "플로럴"
    case softFloral = "소프트 플로럴"
    case floralAmber = "플로럴 앰버"
    case softAmber = "소프트 앰버"
    case amber = "앰버"
    case woodyAmber = "우디 앰버"
    case woods = "우디"
    case mossyWoods = "이끼가 있는 우디"
    case dryWoods = "마른 우디"

    var mainFamily: MainScentFamily {
        switch self {
        case .citrus, .water, .green, .fruity, .aromatic:
            return .fresh
        case .floral, .softFloral, .floralAmber:
            return .floral
        case .softAmber, .amber, .woodyAmber:
            return .amber
        case .woods, .mossyWoods, .dryWoods:
            return .woody
        }
    }

    var englishKey: String {
        switch self {
        case .citrus: return "citrus"
        case .water: return "water"
        case .green: return "green"
        case .fruity: return "fruity"
        case .aromatic: return "aromatic"
        case .floral: return "floral"
        case .softFloral: return "softFloral"
        case .floralAmber: return "floralAmber"
        case .softAmber: return "softAmber"
        case .amber: return "amber"
        case .woodyAmber: return "woodyAmber"
        case .woods: return "woods"
        case .mossyWoods: return "mossyWoods"
        case .dryWoods: return "dryWoods"
        }
    }

    var canonicalName: String {
        switch self {
        case .citrus: return "Citrus"
        case .water: return "Water"
        case .green: return "Green"
        case .fruity: return "Fruity"
        case .aromatic: return "Aromatic"
        case .floral: return "Floral"
        case .softFloral: return "Soft Floral"
        case .floralAmber: return "Floral Amber"
        case .softAmber: return "Soft Amber"
        case .amber: return "Amber"
        case .woodyAmber: return "Woody Amber"
        case .woods: return "Woods"
        case .mossyWoods: return "Mossy Woods"
        case .dryWoods: return "Dry Woods"
        }
    }

    init?(englishKey: String) {
        let normalized = englishKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = Self.allCases.first(where: { $0.englishKey == normalized }) else {
            return nil
        }
        self = match
    }

    init?(canonicalName: String) {
        guard let canonical = ScentFamilyNormalizer.canonicalName(for: canonicalName),
              let match = Self.allCases.first(where: { $0.canonicalName == canonical }) else {
            return nil
        }
        self = match
    }
}

nonisolated struct FragellaAccord {
    let name: String
    let strength: AccordStrength

    var weight: Double {
        switch strength {
        case .dominant: return 4.0
        case .prominent: return 3.0
        case .moderate: return 2.0
        case .subtle: return 1.0
        }
    }

    init(name: String, strength: AccordStrength) {
        self.name = name
        self.strength = strength
    }
}

extension FragellaAccord {
    static func accords(from strengths: [String: AccordStrength]) -> [FragellaAccord] {
        strengths.map { FragellaAccord(name: $0.key, strength: $0.value) }
    }

    static func accords(from perfume: Perfume) -> [FragellaAccord] {
        accords(from: perfume.mainAccordStrengths)
    }

    static func accords(from perfume: CollectedPerfume) -> [FragellaAccord] {
        accords(from: perfume.accordStrengths)
    }
}

nonisolated struct SubFamilyProfile {
    let breakdown: [SubFamily: Double]

    var mainFamilyBreakdown: [MainScentFamily: Double] {
        breakdown.reduce(into: [MainScentFamily: Double]()) { result, pair in
            result[pair.key.mainFamily, default: 0] += pair.value
        }
    }

    var scentVector: [String: Double] {
        breakdown.reduce(into: [String: Double]()) { result, pair in
            result[pair.key.canonicalName] = pair.value / 100
        }
    }

    var mainFamilyScentVector: [String: Double] {
        mainFamilyBreakdown.reduce(into: [String: Double]()) { result, pair in
            result[pair.key.canonicalName] = pair.value / 100
        }
    }

    func visibleSubFamilies(for family: MainScentFamily) -> [SubFamily] {
        let familyPct = mainFamilyBreakdown[family] ?? 0
        let sorted = breakdown
            .filter { $0.key.mainFamily == family }
            .sorted { $0.value > $1.value }
            .map(\.key)

        switch familyPct {
        case 40...:
            return Array(sorted.prefix(2))
        case 20..<40:
            return Array(sorted.prefix(1))
        default:
            return []
        }
    }
}

nonisolated protocol AccordCacheRepository {
    func fetch(accord: String) -> Single<SubFamily?>
    func save(accord: String, subFamily: SubFamily, confidence: Double)
}

nonisolated private let accordToSubFamily: [String: SubFamily] = [
    "citrus": .citrus,
    "fresh citrus": .citrus,
    "fresh": .citrus,
    "aquatic": .water,
    "marine": .water,
    "ozonic": .water,
    "watery": .water,
    "green": .green,
    "herbal": .green,
    "vegetal": .green,
    "fruity": .fruity,
    "tropical": .fruity,
    "juicy": .fruity,
    "aromatic": .aromatic,
    "lavender": .aromatic,
    "fougere": .aromatic,
    "floral": .floral,
    "yellow floral": .floral,
    "rose": .floral,
    "jasmine": .floral,
    "soft floral": .softFloral,
    "white floral": .softFloral,
    "powdery": .softFloral,
    "aldehydic": .softFloral,
    "iris": .softFloral,
    "violet": .softFloral,
    "floral amber": .floralAmber,
    "oriental floral": .floralAmber,
    "floriental": .floralAmber,
    "soft oriental": .softAmber,
    "sweet": .softAmber,
    "vanilla": .softAmber,
    "gourmand": .softAmber,
    "caramel": .softAmber,
    "creamy": .softAmber,
    "tonka bean": .softAmber,
    "amber": .amber,
    "warm spicy": .amber,
    "resinous": .amber,
    "balsamic": .amber,
    "incense": .amber,
    "oriental": .amber,
    "spicy": .amber,
    "warm": .amber,
    "woody amber": .woodyAmber,
    "musky": .woodyAmber,
    "musk": .woodyAmber,
    "patchouli": .woodyAmber,
    "woody": .woods,
    "woods": .woods,
    "wood": .woods,
    "cedar": .woods,
    "sandalwood": .woods,
    "oud": .woods,
    "vetiver": .woods,
    "earthy": .mossyWoods,
    "mossy": .mossyWoods,
    "oakmoss": .mossyWoods,
    "chypre": .mossyWoods,
    "smoky": .dryWoods,
    "leather": .dryWoods,
    "dry": .dryWoods,
    "tobacco": .dryWoods
]

nonisolated private let subFamilyEnglishKey: [String: SubFamily] = Dictionary(
    uniqueKeysWithValues: SubFamily.allCases.map { ($0.englishKey, $0) }
)

nonisolated private func normalizedAccordKey(_ accord: String) -> String {
    accord
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
}

nonisolated private func fuzzyMatch(_ accord: String) -> SubFamily? {
    let lower = normalizedAccordKey(accord)

    if lower.contains("floral") || lower.contains("rose")
        || lower.contains("jasmine") || lower.contains("bloom") { return .floral }
    if lower.contains("wood") || lower.contains("cedar")
        || lower.contains("oud") || lower.contains("sandalwood") { return .woods }
    if lower.contains("amber") || lower.contains("resin")
        || lower.contains("balsam") { return .amber }
    if lower.contains("citrus") || lower.contains("lemon")
        || lower.contains("bergamot") || lower.contains("orange") { return .citrus }
    if lower.contains("fresh") || lower.contains("clean") { return .citrus }
    if lower.contains("sweet") || lower.contains("vanilla")
        || lower.contains("caramel") || lower.contains("cream")
        || lower.contains("gourmand") || lower.contains("ice cream")
        || lower.contains("chocolate") || lower.contains("candy") { return .softAmber }
    if lower.contains("water") || lower.contains("aqua")
        || lower.contains("marine") || lower.contains("ocean") { return .water }
    if lower.contains("green") || lower.contains("herb")
        || lower.contains("grass") { return .green }
    if lower.contains("musk") || lower.contains("musky") { return .woodyAmber }
    if lower.contains("spice") || lower.contains("spicy") { return .amber }
    if lower.contains("smoke") || lower.contains("leather") { return .dryWoods }
    if lower.contains("moss") || lower.contains("earth") { return .mossyWoods }
    if lower.contains("fruit") || lower.contains("berry") { return .fruity }
    if lower.contains("powder") || lower.contains("iris") { return .softFloral }

    return nil
}

nonisolated struct GeminiClassificationResult: Codable {
    let subFamily: String
    let confidence: Double
}

nonisolated final class GeminiAccordClassifier {
    private let geminiAPIKey: String
    private let cache: AccordCacheRepository
    private let confidenceThreshold: Double

    init(
        geminiAPIKey: String,
        cache: AccordCacheRepository,
        confidenceThreshold: Double = 0.6
    ) {
        self.geminiAPIKey = geminiAPIKey
        self.cache = cache
        self.confidenceThreshold = confidenceThreshold
    }

    func classify(accord: String) -> Single<SubFamily?> {
        let normalized = normalizedAccordKey(accord)
        guard !normalized.isEmpty else { return .just(nil) }

        return cache.fetch(accord: normalized)
            .flatMap { [weak self] cached -> Single<SubFamily?> in
                guard let self else { return .just(nil) }
                if let cached { return .just(cached) }
                return self.callGemini(accord: normalized)
            }
    }

    private func callGemini(accord: String) -> Single<SubFamily?> {
        let prompt = """
        You are a fragrance classification expert using Michael Edwards' Fragrance Wheel.
        Classify the following perfume accord into exactly one of the 14 sub-families.

        Sub-family keys:
        citrus, water, green, fruity, aromatic,
        floral, softFloral, floralAmber,
        softAmber, amber, woodyAmber,
        woods, mossyWoods, dryWoods

        Rules:
        - gourmand/sweet/creamy/ice cream/caramel/chocolate -> softAmber
        - spicy/incense/resinous -> amber
        - musky/patchouli -> woodyAmber
        - aldehydic/powdery/iris -> softFloral

        Accord to classify: "\(accord)"

        Respond ONLY with valid JSON. No explanation. No markdown.
        {"subFamily": "softAmber", "confidence": 0.9}
        """

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": ["temperature": 0.1]
        ]

        guard
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(geminiAPIKey)"),
            let data = try? JSONSerialization.data(withJSONObject: body)
        else {
            return .just(nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let accordCache = cache
        let minimumConfidence = confidenceThreshold

        return URLSession.shared.rx.data(request: request)
            .map { data -> (SubFamily, Double)? in
                guard
                    let text = Self.responseText(from: data),
                    let resultData = Self.jsonPayload(from: text).data(using: .utf8),
                    let result = try? JSONDecoder().decode(GeminiClassificationResult.self, from: resultData),
                    result.confidence >= minimumConfidence,
                    let subFamily = subFamilyEnglishKey[result.subFamily]
                else {
                    return nil
                }

                return (subFamily, result.confidence)
            }
            .do(onNext: { classification in
                guard let (subFamily, confidence) = classification else { return }
                accordCache.save(accord: accord, subFamily: subFamily, confidence: confidence)
            })
            .map { $0?.0 }
            .asSingle()
            .catchAndReturn(nil)
    }

    private static func responseText(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]]
        else {
            return nil
        }

        return parts.compactMap { $0["text"] as? String }.joined(separator: "\n")
    }

    private static func jsonPayload(from text: String) -> String {
        let trimmed = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let start = trimmed.firstIndex(of: "{"),
            let end = trimmed.lastIndex(of: "}"),
            start <= end
        else {
            return trimmed
        }

        return String(trimmed[start...end])
    }
}

nonisolated final class SubFamilyClassifier {
    private let geminiClassifier: GeminiAccordClassifier

    init(geminiClassifier: GeminiAccordClassifier) {
        self.geminiClassifier = geminiClassifier
    }

    func classifyPerfume(accords: [FragellaAccord]) -> Single<[SubFamily: Double]> {
        guard !accords.isEmpty else { return .just([:]) }

        let tasks = accords.map { accord -> Single<(SubFamily, Double)?> in
            let lower = normalizedAccordKey(accord.name)

            if let subFamily = accordToSubFamily[lower] {
                return .just((subFamily, accord.weight))
            }

            if let subFamily = fuzzyMatch(lower) {
                return .just((subFamily, accord.weight))
            }

            return geminiClassifier.classify(accord: lower)
                .map { subFamily -> (SubFamily, Double)? in
                    guard let subFamily else { return nil }
                    return (subFamily, accord.weight)
                }
        }

        return Single.zip(tasks).map { results in
            results.reduce(into: [SubFamily: Double]()) { scores, result in
                guard let (subFamily, weight) = result else { return }
                scores[subFamily, default: 0] += weight
            }
        }
    }

    func buildProfile(from perfumeAccordsList: [[FragellaAccord]]) -> Single<SubFamilyProfile> {
        guard !perfumeAccordsList.isEmpty else {
            return .just(SubFamilyProfile(breakdown: [:]))
        }

        let tasks = perfumeAccordsList.map { classifyPerfume(accords: $0) }

        return Single.zip(tasks).map { allScores in
            var totalScores: [SubFamily: Double] = [:]
            for scores in allScores {
                for (subFamily, weight) in scores {
                    totalScores[subFamily, default: 0] += weight
                }
            }

            let total = totalScores.values.reduce(0, +)
            guard total > 0 else {
                return SubFamilyProfile(breakdown: [:])
            }

            return SubFamilyProfile(
                breakdown: totalScores.mapValues { $0 / total * 100 }
            )
        }
    }
}
