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
            case s.contains("woody"), s.contains("wood"):
                return UIColor(hex: "#a07850")
            case s.contains("amber"), s.contains("oriental"), s.contains("warm"):
                return UIColor(hex: "#c8782a")
            case s.contains("fresh"), s.contains("citrus"):
                return UIColor(hex: "#7ecbb8")
            case s.contains("aqua"), s.contains("water"), s.contains("marine"):
                return UIColor(hex: "#4a90b8")
            case s.contains("musk"), s.contains("powdery"):
                return UIColor(hex: "#9FB8C4")
            case s.contains("fruit"), s.contains("green"):
                return UIColor(hex: "#8fba5a")
            case s.contains("aroma"), s.contains("spic"):
                return UIColor(hex: "#9a3a4a")
            default:
                return UIColor.systemGray3
        }
    }

    static func barColor(for family: String) -> UIColor {
        color(for: family)
    }

    static func iconBackground(for profileCode: String) -> UIColor {
        switch profileCode {
        case "P1", "P2":
            return UIColor(hex: "#E1F5EE")
        case "P3", "P4":
            return UIColor(hex: "#FBEAF0")
        case "P5", "P6":
            return UIColor(hex: "#FAEEDA")
        case "P7", "P8":
            return UIColor(hex: "#EEEDFE")
        default:
            return UIColor(hex: "#F1EFE8")
        }
    }

    static func iconEmoji(for profileCode: String) -> String {
        switch profileCode {
        case "P1": return "💧"
        case "P2": return "🍋"
        case "P3": return "🌸"
        case "P4": return "🌹"
        case "P5": return "🪵"
        case "P6": return "🌿"
        case "P7": return "🌙"
        case "P8": return "🔥"
        default: return "✨"
        }
    }
}
