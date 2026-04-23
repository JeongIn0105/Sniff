//
//  ScentFamilyColor.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//
// Sniff — 향 계열별 색상 팔레트

import UIKit

enum ScentFamilyColor {
    static func color(for accord: String) -> UIColor {
        let s = accord.lowercased()
        switch true {
            case s.contains("floral"):
                return UIColor(hex: "#e8a4b8")
            case s.contains("woods"), s.contains("wood"):
                return UIColor(hex: "#a07850")
            case s.contains("amber"), s.contains("oriental"), s.contains("warm"):
                return UIColor(hex: "#c8782a")
            case s.contains("citrus"):
                return UIColor(hex: "#7ecbb8")
            case s.contains("aqua"), s.contains("water"), s.contains("marine"):
                return UIColor(hex: "#4a90b8")
            case s.contains("fruit"), s.contains("green"):
                return UIColor(hex: "#8fba5a")
            case s.contains("aroma"), s.contains("spic"):
                return UIColor(hex: "#9a3a4a")
            case s.contains("soft floral"):
                return UIColor(hex: "#f0b8d1")
            case s.contains("soft amber"):
                return UIColor(hex: "#d88a4d")
            default:
                return UIColor.systemGray3
        }
    }

    static func barColor(for family: String) -> UIColor {
        color(for: family)
    }

    static func iconBackground(for family: String?) -> UIColor {
        guard let family else { return UIColor(hex: "#F1EFE8") }

        switch family {
        case "Citrus", "Fruity", "Green", "Water", "Aromatic":
            return UIColor(hex: "#E1F5EE")
        case "Floral", "Soft Floral", "Floral Amber":
            return UIColor(hex: "#FBEAF0")
        case "Soft Amber", "Amber", "Woody Amber":
            return UIColor(hex: "#FAEEDA")
        case "Woods", "Mossy Woods", "Dry Woods":
            return UIColor(hex: "#EEEDFE")
        default:
            return UIColor(hex: "#F1EFE8")
        }
    }

    static func iconEmoji(for family: String?) -> String {
        guard let family else { return "✨" }

        switch family {
        case "Citrus":
            return "🍋"
        case "Fruity":
            return "🍑"
        case "Green", "Aromatic":
            return "🌿"
        case "Water":
            return "💧"
        case "Floral":
            return "🌹"
        case "Soft Floral":
            return "🌸"
        case "Floral Amber":
            return "🌺"
        case "Soft Amber":
            return "🧡"
        case "Amber", "Woody Amber":
            return "✨"
        case "Woods", "Mossy Woods", "Dry Woods":
            return "🪵"
        default:
            return "✨"
        }
    }
}
