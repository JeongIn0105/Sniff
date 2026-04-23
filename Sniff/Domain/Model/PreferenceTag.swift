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

    nonisolated var displayName: String {
        switch self {
        case .warm: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[0]
        case .cool: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[1]
        case .subtle: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[2]
        case .intense: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[3]
        case .fresh: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[4]
        case .sweet: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[5]
        case .powdery: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[6]
        case .heavy: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[7]
        case .light: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[8]
        case .clean: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[9]
        case .cozy: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[10]
        case .sophisticated: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[11]
        case .luxurious: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[12]
        case .natural: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[13]
        case .mysterious: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[14]
        case .vibrant: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[15]
        case .neutral: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[16]
        case .relaxed: return AppStrings.DomainDisplay.TastingNoteData.moodTagList[17]
        }
    }

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

    nonisolated var relatedScentFamilies: [ScentFamilyFilter] {
        switch self {
        case .warm:
            return [.softAmber, .amber, .woodyAmber, .woods]
        case .cool:
            return [.citrus, .green, .water, .aromatic]
        case .subtle:
            return [.softFloral, .floral, .floralAmber]
        case .intense:
            return [.dryWoods, .woodyAmber, .amber, .woods]
        case .fresh:
            return [.citrus, .green, .water, .fruity]
        case .sweet:
            return [.softAmber, .amber, .fruity]
        case .powdery:
            return [.softFloral, .floralAmber]
        case .heavy:
            return [.amber, .woodyAmber, .mossyWoods, .dryWoods]
        case .light:
            return [.citrus, .green, .water, .floral]
        case .clean:
            return [.softFloral, .water, .green]
        case .cozy:
            return [.softFloral, .softAmber, .amber]
        case .sophisticated:
            return [.woods, .floralAmber, .dryWoods]
        case .luxurious:
            return [.amber, .woodyAmber, .floralAmber, .woods]
        case .natural:
            return [.green, .woods, .aromatic, .floral]
        case .mysterious:
            return [.amber, .woodyAmber, .mossyWoods, .dryWoods]
        case .vibrant:
            return [.citrus, .fruity, .green, .floral]
        case .neutral:
            return [.softFloral, .woods, .aromatic, .water]
        case .relaxed:
            return [.aromatic, .green, .softFloral, .woods]
        }
    }

    static var vibeTags: [PreferenceTag] {
        allCases.filter { $0.category == .vibe }
    }

    static var imageTags: [PreferenceTag] {
        [.warm, .cool, .fresh, .sweet, .clean, .cozy, .intense]
    }
}
