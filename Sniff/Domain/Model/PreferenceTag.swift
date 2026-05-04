//
//  PreferenceTag.swift
//  Sniff
//
//  Created by Codex on 2026.04.17.
//

import Foundation

enum PreferenceTagCategory {
    case vibe
    case image
}

enum PreferenceTag: String, CaseIterable, Codable {
    case sophisticated = "세련된"
    case natural = "자연스러운"
    case mysterious = "신비로운"
    case vibrant = "활기찬"
    case relaxed = "여유로운"
    case pure = "청순한"
    case sensual = "섹시한"
    case calm = "차분한"
    case chic = "시크한"
    case warm = "따뜻한"
    case cool = "시원한"
    case fresh = "상큼한"
    case sweet = "달콤한"
    case clean = "깨끗한"
    case soft = "부드러운"
    case subtle = "은은한"
    case clear = "맑은"
    case deep = "짙은"

    nonisolated var displayName: String {
        rawValue
    }

    var category: PreferenceTagCategory {
        switch self {
        case .sophisticated, .natural, .mysterious, .vibrant, .relaxed, .pure, .sensual, .calm, .chic:
            return .vibe
        case .warm, .cool, .fresh, .sweet, .clean, .soft, .subtle, .clear, .deep:
            return .image
        }
    }

    var relatedAccords: [String] {
        switch self {
        case .warm:
            return ["amber", "vanilla", "woody", "sandalwood", "warm spicy"]
        case .cool:
            return ["aquatic", "fresh", "mint", "eucalyptus", "marine"]
        case .subtle:
            return ["musk", "powdery", "soft floral", "sheer"]
        case .fresh:
            return ["citrus", "fresh", "green", "bergamot", "lemon"]
        case .sweet:
            return ["vanilla", "gourmand", "fruity", "caramel", "honey"]
        case .clean:
            return ["musk", "soap", "aldehyde", "aquatic", "clean"]
        case .soft:
            return ["musk", "soft floral", "sandalwood", "vanilla", "cashmere"]
        case .clear:
            return ["aquatic", "citrus", "herbal", "transparent", "clean"]
        case .deep:
            return ["amber", "oud", "woody", "incense", "smoky"]
        case .sophisticated:
            return ["leather", "iris", "aldehyde", "chypre", "rose"]
        case .natural:
            return ["green", "woody", "earthy", "vetiver", "moss"]
        case .mysterious:
            return ["incense", "oud", "patchouli", "resinous", "dark"]
        case .vibrant:
            return ["citrus", "fruity", "fresh spicy", "aromatic", "energetic"]
        case .relaxed:
            return ["lavender", "woody", "soft musk", "chamomile", "cedar"]
        case .pure:
            return ["soft floral", "musk", "aquatic", "clean", "white floral"]
        case .sensual:
            return ["amber", "floral amber", "musk", "woody amber", "jasmine"]
        case .calm:
            return ["woody", "tea", "soft amber", "lavender", "cedar"]
        case .chic:
            return ["dry woods", "woody amber", "iris", "leather", "aromatic"]
        }
    }

    nonisolated var relatedScentFamilies: [ScentFamilyFilter] {
        switch self {
        case .warm:
            return [.softAmber, .amber, .woodyAmber, .woods]
        case .cool:
            return [.citrus, .green, .water, .aromatic]
        case .subtle:
            return [.softFloral, .floral, .floralAmber]
        case .fresh:
            return [.citrus, .green, .water, .fruity]
        case .sweet:
            return [.softAmber, .amber, .fruity]
        case .clean:
            return [.softFloral, .water, .green]
        case .soft:
            return [.softFloral, .softAmber, .amber]
        case .clear:
            return [.water, .citrus, .aromatic]
        case .deep:
            return [.amber, .woodyAmber, .dryWoods]
        case .sophisticated:
            return [.water, .aromatic, .citrus]
        case .natural:
            return [.green, .woods, .aromatic, .floral]
        case .mysterious:
            return [.water, .amber, .woodyAmber]
        case .vibrant:
            return [.citrus, .fruity, .green, .floral]
        case .relaxed:
            return [.aromatic, .green, .softFloral, .woods]
        case .pure:
            return [.softFloral, .floral, .water]
        case .sensual:
            return [.amber, .woodyAmber, .floralAmber]
        case .calm:
            return [.woods, .softAmber, .aromatic]
        case .chic:
            return [.woods, .dryWoods, .woodyAmber]
        }
    }

    static var vibeTags: [PreferenceTag] {
        allCases.filter { $0.category == .vibe }
    }

    static var imageTags: [PreferenceTag] {
        [.warm, .cool, .fresh, .sweet, .clean, .soft, .subtle, .clear, .deep]
    }
}
