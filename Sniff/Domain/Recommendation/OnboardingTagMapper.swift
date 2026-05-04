//
//  OnboardingTagMapper.swift
//  Sniff
//

import Foundation

enum OnboardingTagMapper {
    nonisolated static let cleanFreshFamilies = ["Citrus", "Fruity", "Green", "Water", "Aromatic"]
    nonisolated static let softFloralFamilies = ["Floral", "Soft Floral"]
    nonisolated static let warmSweetFamilies = ["Floral Amber", "Soft Amber", "Amber"]
    nonisolated static let calmWoodsFamilies = ["Woods", "Woody Amber", "Mossy Woods", "Dry Woods"]
    nonisolated private static let preferredTagFamilyMap: [String: [String]] = [
        "상큼한 레몬 향": ["Citrus", "Fruity"],
        "깨끗한 샤워 향": ["Water", "Aromatic", "Citrus"],
        "싱그러운 풀잎 향": ["Green"],
        "맑은 허브 향": ["Aromatic", "Green"],
        "깨끗한 섬유유연제 향": ["Soft Floral", "Aromatic"],
        "장미꽃 향": ["Floral"],
        "라일락 향": ["Soft Floral", "Floral"],
        "복숭아꽃 향": ["Floral", "Fruity"],
        "포근한 목련 향": ["Soft Floral", "Floral"],
        "진한 재스민 향": ["Floral"],
        "달달한 바닐라 향": ["Soft Amber", "Amber"],
        "포근한 머스크 향": ["Soft Amber"],
        "달콤한 꿀 향": ["Amber", "Floral Amber"],
        "고소한 카라멜 향": ["Amber", "Soft Amber"],
        "따뜻한 코코아 향": ["Amber", "Soft Amber"],
        "비 온 뒤 숲 향": ["Mossy Woods", "Green"],
        "마른 나무 향": ["Dry Woods", "Woods"],
        "묵직한 우드 향": ["Woody Amber", "Dry Woods", "Woods"],
        "따뜻한 차 향": ["Aromatic", "Woods"],
        "이끼 낀 숲 향": ["Mossy Woods", "Green"]
    ]

    nonisolated static func families(for tag: String) -> [String] {
        if let preferredFamilies = preferredTagFamilyMap[tag] {
            return preferredFamilies
        }

        switch tag {
        case "너무 달달한 향", "달콤한 복숭아 향", "과일주스 같은 향", "복숭아꽃 향":
            return ["Fruity"]
        case "머리 아픈 진한 향", "고급 호텔 로비 향":
            return ["Amber", "Woody Amber", "Musk"]
        case "할머니 화장품 같은 향", "화장품 가루 같은 향":
            return ["Powdery", "Soft Floral"]
        case "남자 스킨 같은 향", "매운 향신료 같은 향":
            return ["Aromatic", "Woody Amber"]
        case "절 냄새 같은 향":
            return ["Amber", "Dry Woods"]
        case "담배/스모키한 향", "가죽 같은 향":
            return ["Dry Woods", "Amber"]
        case "비누향", "막 씻고 나온 향", "깨끗한 섬유유연제 향", "햇살에 말린 이불 향", "깨끗한 사람", "은은한 사람", "포근한 머스크 향":
            return ["Musk", "Soft Floral"]
        case "꽃집 같은 향", "은은한 꽃다발 향", "장미꽃 향", "라일락 향", "포근한 목련 향", "진한 자스민 향":
            return ["Floral", "Soft Floral"]
        case "풀 냄새 같은 향", "비 온 뒤 숲 향", "자연스러운 사람", "싱그러운 풀잎 향":
            return ["Green", "Water"]
        case "맑은 허브 향":
            return ["Aromatic", "Green"]
        case "나무 냄새 같은 향", "차분한 나무 향", "차분한 사람", "마른 나무 향", "묵직한 우드 향":
            return ["Woods", "Dry Woods"]
        case "바닐라 같은 향", "포근한 향", "포근한 사람", "다정한 사람", "달달한 바닐라 향", "고소한 카라멜 향":
            return ["Soft Amber", "Amber"]
        case "달콤한 꿀 향":
            return ["Soft Amber", "Floral Amber"]
        case "따뜻한 코코아 향":
            return ["Soft Amber", "Amber"]
        case "따뜻한 차 향":
            return ["Aromatic", "Soft Amber"]
        case "머스크 향":
            return ["Musk"]
        case "흙/이끼 같은 향", "이끼 낀 숲 향":
            return ["Mossy Woods", "Green"]
        case "상큼한 귤껍질 향", "산뜻한 향", "상큼한 사람", "상큼한 레몬":
            return ["Citrus", "Fruity"]
        case "시원한 향", "시원한 바다":
            return ["Water", "Citrus"]
        case "차분한 향":
            return ["Woods", "Soft Amber"]
        case "사계절 무난한 향":
            return ["Musk", "Citrus", "Soft Floral"]
        case "센스 있는 사람", "고급스러운 사람":
            return ["Woody Amber", "Amber", "Soft Floral"]
        case "깨끗하고 산뜻한 향":
            return cleanFreshFamilies
        case "은은한 꽃 향":
            return softFloralFamilies
        case "따뜻하고 달콤한 향":
            return warmSweetFamilies
        case "차분한 숲과 나무 향":
            return calmWoodsFamilies
        default:
            return []
        }
    }

    nonisolated static func searchKeywords(for tag: String) -> [String] {
        switch tag {
        case "깨끗하고 산뜻한 향":
            return ["citrus", "fruity", "green", "aquatic", "aromatic", "fresh"]
        case "은은한 꽃 향":
            return ["floral", "soft floral", "rose", "lilac", "jasmine"]
        case "따뜻하고 달콤한 향":
            return ["floral amber", "soft amber", "amber", "vanilla", "sweet"]
        case "차분한 숲과 나무 향":
            return ["woody", "woody amber", "mossy woods", "dry woods", "forest"]
        case "상큼한 레몬", "상큼한 레몬 향":
            return ["citrus", "lemon", "fresh"]
        case "시원한 바다", "깨끗한 샤워 향":
            return ["aquatic", "marine", "water", "clean", "aromatic"]
        case "맑은 허브 향":
            return ["aromatic", "herbal", "green"]
        case "싱그러운 풀잎 향":
            return ["green", "fresh"]
        case "깨끗한 섬유유연제 향":
            return ["clean", "musk", "soft floral"]
        case "장미꽃 향":
            return ["rose", "floral"]
        case "라일락 향":
            return ["lilac", "floral"]
        case "복숭아꽃 향":
            return ["peach", "fruity", "floral"]
        case "포근한 목련 향":
            return ["magnolia", "soft floral"]
        case "진한 자스민 향", "진한 재스민 향":
            return ["jasmine", "floral"]
        case "달달한 바닐라 향":
            return ["vanilla", "sweet", "soft amber"]
        case "포근한 머스크 향":
            return ["musk", "soft floral"]
        case "달콤한 꿀 향":
            return ["honey", "sweet", "amber"]
        case "고소한 카라멜 향":
            return ["caramel", "gourmand", "soft amber"]
        case "따뜻한 코코아 향":
            return ["cacao", "chocolate", "amber"]
        case "마른 나무 향":
            return ["dry woods", "woody"]
        case "비 온 뒤 숲 향":
            return ["green", "forest", "mossy woods"]
        case "이끼 낀 숲 향":
            return ["mossy woods", "oakmoss", "green"]
        case "따뜻한 차 향":
            return ["tea", "warm", "aromatic"]
        case "묵직한 우드 향":
            return ["woody", "woods", "cedar"]
        default:
            return families(for: tag).flatMap { family in
                searchKeywordsForFamily(family)
            }
        }
    }

    nonisolated static func searchKeywordsForFamily(_ family: String) -> [String] {
        switch family {
        case "Citrus": return ["citrus", "fresh"]
        case "Fruity": return ["fruity", "sweet fruity"]
        case "Green": return ["green", "fresh"]
        case "Water": return ["aquatic", "marine", "water"]
        case "Aromatic": return ["aromatic", "herbal"]
        case "Floral": return ["floral"]
        case "Soft Floral": return ["soft floral", "powdery", "musk"]
        case "Floral Amber": return ["floral amber", "oriental floral"]
        case "Soft Amber": return ["soft amber", "vanilla", "gourmand"]
        case "Amber": return ["amber", "warm spicy"]
        case "Woods": return ["woody", "woods"]
        case "Woody Amber": return ["woody amber", "woody", "amber"]
        case "Mossy Woods": return ["mossy woods", "oakmoss", "chypre"]
        case "Dry Woods": return ["dry woods", "leather", "smoky"]
        default: return []
        }
    }

    nonisolated static func weightedVector(for tags: [String]) -> [String: Double] {
        var scores: [String: Double] = [:]
        for tag in tags {
            for family in families(for: tag) {
                scores[family, default: 0] += 1
            }
        }

        let canonical = scores.reduce(into: [String: Double]()) { result, pair in
            guard let name = ScentFamilyNormalizer.canonicalName(for: pair.key) else { return }
            result[name, default: 0] += pair.value
        }

        let total = canonical.values.reduce(0, +)
        guard total > 0 else { return [:] }
        return canonical.mapValues { $0 / total }
    }

    nonisolated static func preferredFamilies(preferred: [String], season: String?, impression: [String]) -> [String] {
        let tags = preferred + [season].compactMap { $0 } + impression
        let ranked = weightedVector(for: tags).sorted { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.key < rhs.key
        }
        return ranked.map(\.key)
    }
}
