import Foundation

struct FragranceProfileColorPalette: Sendable {
    let accentHex: String
    let primaryHex: String
    let baseHex: String
    let primaryLocation: Double

    init(
        accentHex: String,
        primaryHex: String,
        baseHex: String,
        primaryLocation: Double = 0.45
    ) {
        self.accentHex = accentHex
        self.primaryHex = primaryHex
        self.baseHex = baseHex
        self.primaryLocation = primaryLocation
    }
}

enum FragranceProfileText {
    nonisolated private enum DisplayThreshold {
        static let primaryFamily = 0.45
        static let secondaryFamily = 0.20
    }

    nonisolated static let orderedTasteTitles: [String] = [
        "상큼하고 활기찬 취향",
        "맑고 세련된 취향",
        "시원하고 신비로운 취향",
        "부드럽고 청순한 취향",
        "포근하고 여유로운 취향",
        "달콤하고 화사한 취향",
        "싱그럽고 자연스러운 취향",
        "짙고 시크한 취향",
        "짙고 강렬한 취향"
    ]

    nonisolated static let allowedTasteTitles = Set(orderedTasteTitles)

    nonisolated static func validatedTasteTitle(_ title: String?) -> String? {
        guard let normalized = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !normalized.isEmpty else {
            return nil
        }
        let canonical = legacyTasteTitleAliases[normalized] ?? normalized
        return allowedTasteTitles.contains(canonical) ? canonical : nil
    }

    nonisolated static func displayTitle(for families: [String]) -> String {
        guard let firstFamily = normalizedFamilies(from: families).first else {
            return "취향을 분석하는 중이에요"
        }

        switch firstFamily {
        case "Soft Floral", "Floral Amber":
            return "포근하고 부드러운 취향"
        case "Floral":
            return "은은하고 화사한 취향"
        case "Citrus", "Fruity", "Green", "Water", "Aromatic":
            return "산뜻하고 생기 있는 취향"
        case "Soft Amber", "Amber", "Woody Amber":
            return "따뜻하고 깊이 있는 취향"
        case "Woods", "Mossy Woods", "Dry Woods":
            return "차분하고 깊이 있는 취향"
        default:
            return "\(displayFamilyName(firstFamily)) 중심 취향"
        }
    }

    nonisolated static func inferredDisplayTitle(for families: [String]) -> String {
        inferredTasteTitle(from: families)
            ?? displayTitle(for: families)
    }

    nonisolated static func profileTitle(
        originalTitle: String?,
        scentVector: [String: Double],
        stage: RecommendationStage
    ) -> String {
        let validatedOriginalTitle = validatedTasteTitle(originalTitle)
        switch stage {
        case .onboardingOnly, .onboardingCollection:
            if let validatedOriginalTitle {
                return validatedOriginalTitle
            }
        case .earlyTasting, .heavyTasting:
            break
        }

        let dominantVector = dominantDisplayVector(from: scentVector)
        let fullVector = normalizedVector(from: scentVector)
        let rankedFamilies = rankedFamilies(from: scentVector)

        return inferredTasteTitle(from: dominantVector)
            ?? inferredTasteTitle(from: fullVector)
            ?? validatedOriginalTitle
            ?? inferredTasteTitle(from: rankedFamilies)
            ?? displayTitle(for: rankedFamilies)
    }

    nonisolated static func profileFamilies(forTitle title: String) -> [String]? {
        tasteTitleDisplayFamilies[title]
    }

    nonisolated static func profileColorHex(forTitle title: String) -> String? {
        profileColorPalette(forTitle: title)?.primaryHex
    }

    nonisolated static func profileColorPalette(forTitle title: String) -> FragranceProfileColorPalette? {
        tasteTitleColorPalettes[title]
    }

    nonisolated static func familySummary(for families: [String]) -> String {
        let topFamilies = Array(normalizedFamilies(from: families).prefix(2))

        switch topFamilies.count {
        case 2:
            return "\(displayFamilyName(topFamilies[0])) · \(displayFamilyName(topFamilies[1])) 중심"
        case 1:
            return "\(displayFamilyName(topFamilies[0])) 중심"
        default:
            return ""
        }
    }

    nonisolated static func majorFamilySummary(for families: [String]) -> String {
        let groups = normalizedFamilies(from: families)
            .compactMap(majorGroup(for:))
            .reduce(into: [String]()) { result, group in
                if !result.contains(group) {
                    result.append(group)
                }
            }

        let topGroups = Array(groups.prefix(2))

        switch topGroups.count {
        case 2:
            return "\(topGroups[0]) · \(topGroups[1]) 계열 중심"
        case 1:
            return "\(topGroups[0]) 계열 중심"
        default:
            return ""
        }
    }

    nonisolated static func leadingFamily(from families: [String]) -> String? {
        normalizedFamilies(from: families).first
    }

    nonisolated static func normalizedFamilies(from families: [String]) -> [String] {
        var seen = Set<String>()

        return families
            .compactMap { ScentFamilyNormalizer.canonicalName(for: $0) }
            .filter { seen.insert($0).inserted }
    }

    nonisolated static func dominantDisplayFamilies(from scentVector: [String: Double]) -> [String] {
        let ranked = rankedVector(from: scentVector)

        guard let first = ranked.first, first.value >= DisplayThreshold.primaryFamily else {
            return []
        }

        var result = [first.key]
        if ranked.count > 1 {
            let second = ranked[1]
            if second.value >= DisplayThreshold.secondaryFamily {
                result.append(second.key)
            }
        }

        return result
    }

    nonisolated static func rankedFamilies(from scentVector: [String: Double]) -> [String] {
        rankedVector(from: scentVector).map(\.key)
    }

    nonisolated private static func majorGroup(for family: String) -> String? {
        switch family {
        case "Citrus", "Fruity", "Green", "Water", "Aromatic":
            return "프레쉬"
        case "Floral", "Soft Floral", "Floral Amber":
            return "플로럴"
        case "Soft Amber", "Amber", "Woody Amber":
            return "앰버"
        case "Woods", "Mossy Woods", "Dry Woods":
            return "우디"
        default:
            return nil
        }
    }

    nonisolated static func displayFamilyName(_ family: String) -> String {
        PerfumeKoreanTranslator.koreanFamily(for: family)
    }

    nonisolated private static func dominantDisplayVector(from scentVector: [String: Double]) -> [String: Double] {
        let displayFamilies = dominantDisplayFamilies(from: scentVector)
        guard !displayFamilies.isEmpty else { return [:] }

        let normalized = normalizedVector(from: scentVector)
        return displayFamilies.reduce(into: [String: Double]()) { result, family in
            result[family] = normalized[family, default: 0]
        }
    }

    nonisolated private static func normalizedVector(from scentVector: [String: Double]) -> [String: Double] {
        scentVector.reduce(into: [String: Double]()) { result, pair in
            guard let canonical = ScentFamilyNormalizer.canonicalName(for: pair.key), pair.value > 0 else {
                return
            }
            result[canonical, default: 0] += pair.value
        }
    }

    nonisolated private static func rankedVector(from scentVector: [String: Double]) -> [(key: String, value: Double)] {
        normalizedVector(from: scentVector)
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
            }
    }

    nonisolated private static func inferredTasteTitle(from scentVector: [String: Double]) -> String? {
        let normalizedVector = normalizedVector(from: scentVector)
        guard !normalizedVector.isEmpty else { return nil }

        let scoredTitles = orderedTasteTitles.map { title in
            (title: title, score: tasteTitleFamilyHints[title, default: [:]].reduce(0) { partial, pair in
                partial + normalizedVector[pair.key, default: 0] * pair.value
            })
        }

        guard let best = scoredTitles.max(by: { $0.score < $1.score }), best.score > 0 else {
            return nil
        }
        return best.title
    }

    nonisolated private static func inferredTasteTitle(from families: [String]) -> String? {
        let normalizedFamilies = normalizedFamilies(from: families)
        guard !normalizedFamilies.isEmpty else { return nil }

        let vector = normalizedFamilies.enumerated().reduce(into: [String: Double]()) { result, pair in
            let weight = max(1, normalizedFamilies.count - pair.offset)
            result[pair.element, default: 0] += Double(weight)
        }
        return inferredTasteTitle(from: vector)
    }

    nonisolated private static let tasteTitleFamilyHints: [String: [String: Double]] = [
        "상큼하고 활기찬 취향": [
            "Citrus": 1.0,
            "Fruity": 0.9,
            "Green": 0.45,
            "Aromatic": 0.35
        ],
        "맑고 세련된 취향": [
            "Water": 1.0,
            "Aromatic": 0.90,
            "Citrus": 0.70,
            "Soft Floral": 0.35
        ],
        "시원하고 신비로운 취향": [
            "Aromatic": 0.95,
            "Water": 0.75,
            "Woods": 0.45,
            "Woody Amber": 0.45
        ],
        "부드럽고 청순한 취향": [
            "Soft Floral": 1.0,
            "Floral": 0.9,
            "Water": 0.5,
            "Soft Amber": 0.4
        ],
        "포근하고 여유로운 취향": [
            "Soft Amber": 1.0,
            "Soft Floral": 0.8,
            "Woods": 0.6,
            "Amber": 0.5
        ],
        "달콤하고 화사한 취향": [
            "Fruity": 1.0,
            "Floral Amber": 0.9,
            "Amber": 0.6,
            "Soft Amber": 0.5
        ],
        "싱그럽고 자연스러운 취향": [
            "Green": 1.0,
            "Mossy Woods": 0.85,
            "Water": 0.55,
            "Aromatic": 0.40
        ],
        "짙고 시크한 취향": [
            "Woods": 1.0,
            "Dry Woods": 1.0,
            "Woody Amber": 0.75,
            "Aromatic": 0.30
        ],
        "짙고 강렬한 취향": [
            "Amber": 1.0,
            "Woody Amber": 0.9,
            "Dry Woods": 0.45,
            "Mossy Woods": 0.35
        ]
    ]

    nonisolated private static let tasteTitleDisplayFamilies: [String: [String]] = [
        "상큼하고 활기찬 취향": ["Citrus", "Fruity"],
        "맑고 세련된 취향": ["Water", "Aromatic"],
        "시원하고 신비로운 취향": ["Water", "Aromatic"],
        "부드럽고 청순한 취향": ["Soft Floral", "Floral"],
        "포근하고 여유로운 취향": ["Soft Amber", "Soft Floral"],
        "달콤하고 화사한 취향": ["Fruity", "Floral Amber"],
        "싱그럽고 자연스러운 취향": ["Green", "Water"],
        "짙고 시크한 취향": ["Woods", "Dry Woods"],
        "짙고 강렬한 취향": ["Amber", "Woody Amber"]
    ]

    nonisolated private static let tasteTitleColorPalettes: [String: FragranceProfileColorPalette] = [
        "상큼하고 활기찬 취향": FragranceProfileColorPalette(
            accentHex: "#FFAB7D",
            primaryHex: "#F2E6AD",
            baseHex: "#F2E8DE"
        ),
        "맑고 세련된 취향": FragranceProfileColorPalette(
            accentHex: "#F7EFCB",
            primaryHex: "#B9DDEA",
            baseHex: "#F2E8DE",
            primaryLocation: 0.52
        ),
        "시원하고 신비로운 취향": FragranceProfileColorPalette(
            accentHex: "#CDBED4",
            primaryHex: "#99CFE3",
            baseHex: "#F2E8DE"
        ),
        // Figma EllipticalGradient: Color(0.95,0.9,0.68) → Color(0.66,0.81,0.91) → Color(0.95,0.91,0.87)
        "부드럽고 청순한 취향": FragranceProfileColorPalette(
            accentHex: "#F2E6AD",  // 연노랑 (상단 중심)
            primaryHex: "#A8CFE8",  // 연파랑 (중간)
            baseHex: "#F2E8DE",     // 크림 (외곽)
            primaryLocation: 0.45
        ),
        // 수정: 진한 핑크를 center(accent), 밝은 핑크를 middle(primary)
        // 중심→진한핑크 → 중간→연한핑크 → 외곽→크림: blob 없는 부드러운 그라데이션
        "포근하고 여유로운 취향": FragranceProfileColorPalette(
            accentHex: "#D173AB",  // 진한 핑크-퍼플 (center/top)
            primaryHex: "#EFA8B7", // 연한 핑크 (middle)
            baseHex: "#F2E8DE"     // 크림 (edge/bottom)
        ),
        "달콤하고 화사한 취향": FragranceProfileColorPalette(
            accentHex: "#F38BCB",
            primaryHex: "#FFAB7D",
            baseHex: "#F2E8DE"
        ),
        "싱그럽고 자연스러운 취향": FragranceProfileColorPalette(
            accentHex: "#99CFE3",
            primaryHex: "#B8DFA5",
            baseHex: "#F2E8DE"
        ),
        "짙고 시크한 취향": FragranceProfileColorPalette(
            accentHex: "#C8A77E",
            primaryHex: "#D7C8B6",
            baseHex: "#F2E8DE"
        ),
        // 수정: 딥로즈를 center, 웜골드를 middle
        "짙고 강렬한 취향": FragranceProfileColorPalette(
            accentHex: "#B95770",  // 딥로즈 (center/top)
            primaryHex: "#C8A77E", // 웜골드 (middle)
            baseHex: "#F2E8DE"     // 크림 (edge)
        )
    ]

    nonisolated private static let legacyTasteTitleAliases: [String: String] = [
        "달콤하고 신비로운 취향": "달콤하고 화사한 취향",
        "깨끗하고 자연스러운 취향": "싱그럽고 자연스러운 취향"
    ]
}

extension UserTasteProfile {
    var displayFamilies: [String] {
        let title = FragranceProfileText.profileTitle(
            originalTitle: tasteTitle,
            scentVector: scentVector,
            stage: stage
        )

        if let profileFamilies = FragranceProfileText.profileFamilies(forTitle: title) {
            return profileFamilies
        }

        let dominantFamilies = FragranceProfileText.dominantDisplayFamilies(from: scentVector)
        if !dominantFamilies.isEmpty {
            return dominantFamilies
        }
        let rankedFamilies = FragranceProfileText.rankedFamilies(from: scentVector)
        if !rankedFamilies.isEmpty {
            return Array(rankedFamilies.prefix(2))
        }
        return preferredFamilies
    }

    var displayTitle: String {
        FragranceProfileText.profileTitle(
            originalTitle: tasteTitle,
            scentVector: scentVector,
            stage: stage
        )
    }

    var displayFamilySummary: String {
        FragranceProfileText.familySummary(for: displayFamilies)
    }

    var displayMajorSummary: String {
        FragranceProfileText.majorFamilySummary(for: displayFamilies)
    }

    var displayLeadingFamily: String? {
        FragranceProfileText.leadingFamily(from: displayFamilies)
    }
}

extension TasteAnalysisResult {
    var displayTitle: String {
        if let tasteTitle = FragranceProfileText.validatedTasteTitle(tasteTitle) {
            return tasteTitle
        }
        return FragranceProfileText.inferredDisplayTitle(for: recommendationDirection.preferredFamilies)
    }

    var displayFamilySummary: String {
        FragranceProfileText.familySummary(for: recommendationDirection.preferredFamilies)
    }

    var displayMajorSummary: String {
        FragranceProfileText.majorFamilySummary(for: recommendationDirection.preferredFamilies)
    }
}
