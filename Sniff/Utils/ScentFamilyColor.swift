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
        canonicalColor(for: accord)
    }

    static func barColor(for family: String) -> UIColor {
        color(for: family)
    }

    static func chipColors(for family: String) -> (background: UIColor, foreground: UIColor) {
        let background = canonicalColor(for: family)
        let foreground = prefersDarkForeground(for: family) ? UIColor(hex: "#4A4300") : .white
        return (background, foreground)
    }

    static func softBackground(for family: String) -> UIColor {
        canonicalColor(for: family).mixed(with: .white, ratio: 0.82)
    }

    static func softForeground(for family: String) -> UIColor {
        let base = canonicalColor(for: family)
        if prefersDarkForeground(for: family) {
            return UIColor(hex: "#5C5200")
        }
        return base.mixed(with: .black, ratio: 0.18)
    }

    static func iconBackground(for family: String?) -> UIColor {
        guard let family else { return UIColor(hex: "#F1EFE8") }
        return softBackground(for: family)
    }

    static func iconEmoji(for family: String?) -> String {
        ""
    }

    private static func canonicalColor(for family: String) -> UIColor {
        let normalized = family.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch true {
        case normalized.contains("fresh floral"), normalized.contains("프레시 플로럴"):
            return UIColor(hex: "#F29388")
        case normalized.contains("soft floral"),
             normalized.contains("소프트 플로럴"),
             normalized.contains("white floral"),
             normalized.contains("화이트 플로럴"):
            return UIColor(hex: "#F29388")
        case normalized.contains("floral oriental"),
             normalized.contains("플로럴 오리엔탈"),
             normalized.contains("floral amber"),
             normalized.contains("플로럴 앰버"):
            return UIColor(hex: "#B7647B")
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
            return UIColor(hex: "#F29388")
        case normalized.contains("soft oriental"),
             normalized.contains("소프트 오리엔탈"),
             normalized.contains("soft amber"),
             normalized.contains("소프트 앰버"):
            return UIColor(hex: "#B7647B")
        case normalized == "oriental",
             normalized.contains("오리엔탈"),
             normalized == "amber",
             normalized.contains("앰버"):
            return UIColor(hex: "#B7647B")
        case normalized.contains("woody oriental"),
             normalized.contains("우디 오리엔탈"),
             normalized.contains("woody amber"),
             normalized.contains("우디 앰버"):
            return UIColor(hex: "#C36216")
        case normalized.contains("mossy woods"),
             normalized.contains("모씨 우즈"),
             normalized.contains("모시 우즈"),
             normalized.contains("mossy"),
             normalized.contains("moss"),
             normalized.contains("모씨"),
             normalized.contains("earthy"),
             normalized.contains("어시"),
             normalized.contains("이끼"):
            return UIColor(hex: "#3D7F68")
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
            return UIColor(hex: "#9A9566")
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
            return UIColor(hex: "#C58A3B")
        case normalized.contains("aromatic"),
             normalized.contains("아로마틱"),
             normalized.contains("fougere"),
             normalized.contains("푸제르"),
             normalized.contains("powdery"),
             normalized.contains("파우더리"),
             normalized.contains("musk"),
             normalized.contains("머스크"),
             normalized.contains("머스키"),
             normalized.contains("spic"):
            return UIColor(hex: "#68629D")
        case normalized.contains("citrus"),
             normalized.contains("시트러스"):
            return UIColor(hex: "#FFD22E")
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
            return UIColor(hex: "#1D99C4")
        case normalized.contains("green"),
             normalized.contains("그린"):
            return UIColor(hex: "#72BE68")
        case normalized.contains("fresh"),
             normalized.contains("프레시"),
             normalized.contains("프레쉬"):
            return UIColor(hex: "#72BE68")
        case normalized.contains("fruit"),
             normalized.contains("fruity"),
             normalized.contains("프루티"):
            return UIColor(hex: "#E7A175")
        default:
            return UIColor.systemGray3
        }
    }

    private static func prefersDarkForeground(for family: String) -> Bool {
        let normalized = family.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.contains("citrus") || normalized.contains("시트러스")
    }
}

private extension UIColor {
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
