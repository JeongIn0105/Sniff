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
    case warm = "따뜻한"
    case cool = "시원한"
    case subtle = "은은한"
    case intense = "강렬한"
    case fresh = "상큼한"
    case sweet = "달콤한"
    case powdery = "보송보송한"
    case heavy = "묵직한"
    case light = "가벼운"
    case clean = "깨끗한"
    case cozy = "포근한"
    case sophisticated = "세련된"
    case luxurious = "고급스러운"
    case natural = "자연스러운"
    case mysterious = "신비로운"
    case vibrant = "활기찬"
    case neutral = "중성적인"
    case relaxed = "여유로운"

    var displayName: String { rawValue }

    var category: PreferenceTagCategory {
        switch self {
        case .sophisticated, .luxurious, .natural, .mysterious, .vibrant, .neutral, .relaxed:
            return .vibe
        case .warm, .cool, .subtle, .intense, .fresh, .sweet, .powdery, .heavy, .light, .clean, .cozy:
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
        case .intense:
            return ["oud", "leather", "spicy", "incense", "smoky"]
        case .fresh:
            return ["citrus", "fresh", "green", "bergamot", "lemon"]
        case .sweet:
            return ["vanilla", "gourmand", "fruity", "caramel", "honey"]
        case .powdery:
            return ["powdery", "iris", "violet", "talc", "soft floral"]
        case .heavy:
            return ["oud", "amber", "resinous", "leather", "patchouli"]
        case .light:
            return ["fresh", "citrus", "aquatic", "floral", "sheer"]
        case .clean:
            return ["musk", "soap", "aldehyde", "aquatic", "clean"]
        case .cozy:
            return ["sandalwood", "vanilla", "soft floral", "musk", "cashmere"]
        case .sophisticated:
            return ["leather", "iris", "aldehyde", "chypre", "rose"]
        case .luxurious:
            return ["amber", "oud", "rose", "sandalwood", "resinous"]
        case .natural:
            return ["green", "woody", "earthy", "vetiver", "moss"]
        case .mysterious:
            return ["incense", "oud", "patchouli", "resinous", "dark"]
        case .vibrant:
            return ["citrus", "fruity", "fresh spicy", "aromatic", "energetic"]
        case .neutral:
            return ["musk", "woody", "aquatic", "aromatic", "clean"]
        case .relaxed:
            return ["lavender", "woody", "soft musk", "chamomile", "cedar"]
        }
    }

    var relatedScentFamilies: [ScentFamilyFilter] {
        switch self {
        case .warm:
            return [.amber, .vanilla, .woody, .spicy, .musky]
        case .cool:
            return [.citrus, .green, .aquatic, .aromatic]
        case .subtle:
            return [.powdery, .musky, .floral, .whiteFloral]
        case .intense:
            return [.woody, .amber, .spicy, .leather]
        case .fresh:
            return [.citrus, .green, .aquatic, .fruity]
        case .sweet:
            return [.vanilla, .gourmand, .fruity, .amber]
        case .powdery:
            return [.powdery, .musky, .whiteFloral]
        case .heavy:
            return [.amber, .woody, .spicy, .leather]
        case .light:
            return [.citrus, .green, .aquatic, .floral]
        case .clean:
            return [.musky, .powdery, .aquatic, .whiteFloral]
        case .cozy:
            return [.vanilla, .musky, .powdery, .amber]
        case .sophisticated:
            return [.woody, .rose, .whiteFloral, .leather]
        case .luxurious:
            return [.amber, .woody, .rose, .vanilla, .leather]
        case .natural:
            return [.green, .woody, .aromatic, .floral]
        case .mysterious:
            return [.amber, .woody, .spicy, .leather, .rose]
        case .vibrant:
            return [.citrus, .fruity, .green, .floral]
        case .neutral:
            return [.musky, .woody, .aromatic, .aquatic]
        case .relaxed:
            return [.aromatic, .green, .musky, .woody]
        }
    }

    static var vibeTags: [PreferenceTag] {
        allCases.filter { $0.category == .vibe }
    }

    static var imageTags: [PreferenceTag] {
        [.warm, .cool, .fresh, .sweet, .clean, .cozy, .intense]
    }
}
