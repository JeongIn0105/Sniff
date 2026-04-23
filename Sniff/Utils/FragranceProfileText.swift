import Foundation

enum FragranceProfileText {

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
            return "\(firstFamily) 중심 취향"
        }
    }

    nonisolated static func familySummary(for families: [String]) -> String {
        let topFamilies = Array(normalizedFamilies(from: families).prefix(2))

        switch topFamilies.count {
        case 2:
            return "\(topFamilies[0]) · \(topFamilies[1]) 중심"
        case 1:
            return "\(topFamilies[0]) 중심"
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

    nonisolated private static func majorGroup(for family: String) -> String? {
        switch family {
        case "Citrus", "Fruity", "Green", "Water", "Aromatic":
            return "Fresh"
        case "Floral", "Soft Floral", "Floral Amber":
            return "Floral"
        case "Soft Amber", "Amber", "Woody Amber":
            return "Amber"
        case "Woods", "Mossy Woods", "Dry Woods":
            return "Woody"
        default:
            return nil
        }
    }
}

extension UserTasteProfile {
    var displayFamilies: [String] {
        let rankedFamilies = scentVector
            .sorted { $0.value > $1.value }
            .map(\.key)

        return rankedFamilies.isEmpty ? preferredFamilies : rankedFamilies
    }

    var displayTitle: String {
        FragranceProfileText.displayTitle(for: displayFamilies)
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
        FragranceProfileText.displayTitle(for: recommendationDirection.preferredFamilies)
    }

    var displayFamilySummary: String {
        FragranceProfileText.familySummary(for: recommendationDirection.preferredFamilies)
    }

    var displayMajorSummary: String {
        FragranceProfileText.majorFamilySummary(for: recommendationDirection.preferredFamilies)
    }
}
