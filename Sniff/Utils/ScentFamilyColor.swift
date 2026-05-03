//
//  ScentFamilyColor.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//
// Sniff — 향 계열별 색상 팔레트

import UIKit

enum ScentFamilyColor {
    private enum Palette {
        static let floral = UIColor(hex: "#DE9B8B")
        static let softFloral = UIColor(hex: "#D9AEB7")
        static let floralAmber = UIColor(hex: "#D189BB")
        static let softAmber = UIColor(hex: "#B67DA7")
        static let amber = UIColor(hex: "#A36777")
        static let woodyAmber = UIColor(hex: "#C5AA89")
        static let woody = UIColor(hex: "#CCBC9C")
        static let mossyWoods = UIColor(hex: "#95AAAE")
        static let dryWoods = UIColor(hex: "#BCBCA9")
        static let aromatic = UIColor(hex: "#C8BFD2")
        static let citrus = UIColor(hex: "#EBE5B4")
        static let aquatic = UIColor(hex: "#B1CCDF")
        static let green = UIColor(hex: "#C7DAAE")
        static let fruity = UIColor(hex: "#E3B286")
        static let musk = UIColor(hex: "#E8E1D9")
        static let powdery = UIColor(hex: "#EFE9F0")
        static let unknown = UIColor.systemGray3
        static let neutralIconBackground = UIColor(hex: "#F1EFE8")
        static let citrusChipForeground = UIColor(hex: "#4A4300")
        static let citrusSoftForeground = UIColor(hex: "#5C5200")
    }

    static func color(for accord: String) -> UIColor {
        canonicalColor(for: accord)
    }

    static func barColor(for family: String) -> UIColor {
        color(for: family)
    }

    static func chipColors(for family: String) -> (background: UIColor, foreground: UIColor) {
        let background = canonicalColor(for: family)
        let foreground = prefersDarkForeground(for: family) ? Palette.citrusChipForeground : .white
        return (background, foreground)
    }

    static func softBackground(for family: String) -> UIColor {
        canonicalColor(for: family).mixed(with: .white, ratio: 0.82)
    }

    static func softForeground(for family: String) -> UIColor {
        let base = canonicalColor(for: family)
        if prefersDarkForeground(for: family) {
            return Palette.citrusSoftForeground
        }
        return base.mixed(with: .black, ratio: 0.18)
    }

    static func iconBackground(for family: String?) -> UIColor {
        guard let family else { return Palette.neutralIconBackground }
        return softBackground(for: family)
    }

    static func gradientColor(for family: String, base: UIColor, ratio: CGFloat) -> UIColor {
        canonicalColor(for: family).mixed(with: base, ratio: ratio)
    }

    static func iconEmoji(for family: String?) -> String {
        ""
    }

    private static func canonicalColor(for family: String) -> UIColor {
        let normalized = family.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch true {
        case normalized.contains("fresh floral"), normalized.contains("프레시 플로럴"):
            return Palette.softFloral
        case normalized.contains("soft floral"),
             normalized.contains("소프트 플로럴"),
             normalized.contains("white floral"),
             normalized.contains("화이트 플로럴"):
            return Palette.softFloral
        case normalized.contains("floral oriental"),
             normalized.contains("플로럴 오리엔탈"),
             normalized.contains("floral amber"),
             normalized.contains("플로럴 앰버"):
            return Palette.floralAmber
        case normalized == "floral",
             normalized.contains(" floral"),
             normalized.contains("floral "),
             normalized.contains("플로럴"),
             normalized.contains("rose"),
             normalized.contains("로즈"),
             normalized.contains("jasmine"),
             normalized.contains("재스민"),
             normalized.contains("iris"),
             normalized.contains("아이리스"),
             normalized.contains("tuberose"),
             normalized.contains("튜베로즈"),
             normalized.contains("violet"),
             normalized.contains("바이올렛"),
             normalized.contains("lily"),
             normalized.contains("릴리"),
             normalized.contains("gardenia"),
             normalized.contains("가디니아"),
             normalized.contains("magnolia"),
             normalized.contains("마그놀리아"),
             normalized.contains("peony"),
             normalized.contains("피오니"),
             normalized.contains("ylang"),
             normalized.contains("일랑"),
             normalized.contains("neroli"),
             normalized.contains("네롤리"),
             normalized.contains("orange blossom"),
             normalized.contains("오렌지 블로섬"):
            return Palette.floral
        case normalized.contains("soft oriental"),
             normalized.contains("소프트 오리엔탈"),
             normalized.contains("soft amber"),
             normalized.contains("소프트 앰버"):
            return Palette.softAmber
        case normalized == "oriental",
             normalized.contains("오리엔탈"),
             normalized == "amber",
             normalized.contains("앰버"):
            return Palette.amber
        case normalized.contains("woody oriental"),
             normalized.contains("우디 오리엔탈"),
             normalized.contains("woody amber"),
             normalized.contains("우디 앰버"):
            return Palette.woodyAmber
        case normalized.contains("mossy woods"),
             normalized.contains("모씨 우즈"),
             normalized.contains("모시 우즈"),
             normalized.contains("mossy"),
             normalized.contains("moss"),
             normalized.contains("모씨"),
             normalized.contains("earthy"),
             normalized.contains("어시"),
             normalized.contains("이끼"):
            return Palette.mossyWoods
        case normalized.contains("dry woods"),
             normalized.contains("드라이 우즈"),
             normalized.contains("leather"),
             normalized.contains("레더"),
             normalized.contains("smoky"),
             normalized.contains("스모키"),
             normalized.contains("tobacco"),
             normalized.contains("타바코"),
             normalized.contains("incense"),
             normalized.contains("인센스"),
             normalized.contains("resin"),
             normalized.contains("레진"):
            return Palette.dryWoods
        case normalized == "woods",
             normalized == "woody",
             normalized == "우즈",
             normalized == "우드",
             normalized.contains("fresh woody"),
             normalized.contains("프레시 우디"),
             normalized.contains("woody spicy"),
             normalized.contains("우디 스파이시"),
             normalized.contains("woody"),
             normalized.contains("우즈"),
             normalized.contains("우디"):
            return Palette.woody
        case normalized.contains("musk"),
             normalized.contains("머스크"),
             normalized.contains("머스키"):
            return Palette.musk
        case normalized.contains("powdery"),
             normalized.contains("파우더리"):
            return Palette.powdery
        case normalized.contains("aromatic"),
             normalized.contains("아로마틱"),
             normalized.contains("fougere"),
             normalized.contains("푸제르"),
             normalized.contains("스파이시"),
             normalized.contains("spic"):
            return Palette.aromatic
        case normalized.contains("citrus"),
             normalized.contains("시트러스"):
            return Palette.citrus
        case normalized.contains("water"),
             normalized.contains("워터"),
             normalized.contains("aqua"),
             normalized.contains("aquatic"),
             normalized.contains("marine"),
             normalized.contains("clean"),
             normalized.contains("클린"),
             normalized.contains("soapy"),
             normalized.contains("소피"),
             normalized.contains("soap"):
            return Palette.aquatic
        case normalized.contains("green"),
             normalized.contains("그린"):
            return Palette.green
        case normalized.contains("fresh"),
             normalized.contains("프레시"),
             normalized.contains("프레쉬"):
            return Palette.green
        case normalized.contains("fruit"),
             normalized.contains("fruity"),
             normalized.contains("프루티"):
            return Palette.fruity
        default:
            return Palette.unknown
        }
    }

    private static func prefersDarkForeground(for family: String) -> Bool {
        let normalized = family.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.contains("citrus") || normalized.contains("시트러스")
    }
}

extension UIColor {
    func mixed(with other: UIColor, ratio: CGFloat) -> UIColor {
        let ratio = max(0, min(1, ratio))

        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(
            red: r1 * (1 - ratio) + r2 * ratio,
            green: g1 * (1 - ratio) + g2 * ratio,
            blue: b1 * (1 - ratio) + b2 * ratio,
            alpha: a1 * (1 - ratio) + a2 * ratio
        )
    }
}
