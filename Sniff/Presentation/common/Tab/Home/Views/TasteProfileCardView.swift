//
//  TasteProfileCardView.swift
//  Sniff
//

import UIKit

struct TasteProfileGradientPreset: Identifiable {
    let title: String
    let subtitle: String
    let colors: [UIColor]
    let locations: [NSNumber]

    var id: String { title }

    static func preset(forTitle title: String) -> TasteProfileGradientPreset? {
        presets.first { $0.title == title }
    }

    static let presets: [TasteProfileGradientPreset] = [
        .init(
            title: "상큼하고 활기찬 취향",
            subtitle: "시트러스 · 프루티 중심",
            colors: [
                UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1),
                UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        ),
        .init(
            title: "맑고 세련된 취향",
            subtitle: "워터 · 아로마틱 · 시트러스 중심",
            colors: [
                UIColor(red: 0.97, green: 0.94, blue: 0.80, alpha: 1),
                UIColor(red: 0.73, green: 0.87, blue: 0.92, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.52, 1.00]
        ),
        .init(
            title: "시원하고 신비로운 취향",
            subtitle: "워터 · 아로마틱 중심",
            colors: [
                UIColor(red: 0.80, green: 0.75, blue: 0.83, alpha: 1),
                UIColor(red: 0.60, green: 0.81, blue: 0.89, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        ),
        .init(
            title: "부드럽고 청순한 취향",
            subtitle: "소프트 플로럴 · 플로럴 · 워터 중심",
            colors: [
                UIColor(red: 1.00, green: 0.56, blue: 0.53, alpha: 1),
                UIColor(red: 0.94, green: 0.66, blue: 0.72, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        ),
        .init(
            title: "포근하고 여유로운 취향",
            subtitle: "소프트 앰버 · 소프트 플로럴 · 우디 중심",
            colors: [
                UIColor(red: 0.94, green: 0.66, blue: 0.72, alpha: 1),
                UIColor(red: 0.82, green: 0.45, blue: 0.67, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        ),
        .init(
            title: "달콤하고 화사한 취향",
            subtitle: "프루티 · 플로럴 앰버 · 앰버 중심",
            colors: [
                UIColor(red: 0.94, green: 0.48, blue: 0.75, alpha: 1),
                UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        ),
        .init(
            title: "싱그럽고 자연스러운 취향",
            subtitle: "그린 · 모시 우즈 · 워터 중심",
            colors: [
                UIColor(red: 0.60, green: 0.81, blue: 0.89, alpha: 1),
                UIColor(red: 0.74, green: 0.87, blue: 0.66, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        ),
        .init(
            title: "짙고 시크한 취향",
            subtitle: "우디 · 드라이 우즈 · 우디 앰버 중심",
            colors: [
                UIColor(red: 0.75, green: 0.74, blue: 0.65, alpha: 1),
                UIColor(red: 0.84, green: 0.73, blue: 0.59, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        ),
        .init(
            title: "짙고 강렬한 취향",
            subtitle: "앰버 · 우디 앰버 중심",
            colors: [
                UIColor(red: 0.84, green: 0.65, blue: 0.52, alpha: 1),
                UIColor(red: 0.75, green: 0.36, blue: 0.47, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            locations: [0.20, 0.45, 1.00]
        )
    ]
}

final class TasteProfileGradientIconView: UIView {

    private var colors: [UIColor] = [
        UIColor(red: 1.0, green: 0.67, blue: 0.49, alpha: 1),
        UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1),
        UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
    ]
    private var locations: [CGFloat] = [0.20, 0.45, 1.00]
    private var centerPoint = CGPoint(x: 0.5, y: 0.04)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.masksToBounds = true
        contentMode = .redraw
        backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              !rect.isEmpty,
              let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors.map(\.cgColor) as CFArray,
                locations: locations
              ) else {
            return
        }

        let path = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: layer.cornerRadius
        )
        context.saveGState()
        path.addClip()

        let center = CGPoint(
            x: bounds.minX + bounds.width * centerPoint.x,
            y: bounds.minY + bounds.height * centerPoint.y
        )
        let farthestX = max(center.x - bounds.minX, bounds.maxX - center.x)
        let farthestY = max(center.y - bounds.minY, bounds.maxY - center.y)
        let radius = sqrt(farthestX * farthestX + farthestY * farthestY)

        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )

        context.restoreGState()
    }

    func configure(families: [String]) {
        let baseBeige = UIColor(red: Double(0xF1) / 255.0, green: Double(0xE8) / 255.0, blue: Double(0xDF) / 255.0, alpha: 1)

        let colors: [UIColor]
        if families.isEmpty {
            colors = [
                UIColor(red: 1.0, green: 0.67, blue: 0.49, alpha: 1).softened(amount: 0.10),
                UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1).softened(amount: 0.10),
                baseBeige
            ]
        } else {
            let top1 = ScentFamilyColor.color(for: families[0]).softened(amount: 0.30)
            let top2 = families.count > 1
                ? ScentFamilyColor.color(for: families[1]).softened(amount: 0.20)
                : top1.softened(amount: 0.20)
            colors = [top2, top1, baseBeige]
        }

        configure(exactColors: colors, locations: [0.20, 0.45, 1.00])
    }

    func configure(title: String, fallbackFamilies: [String]) {
        if let exactPreset = Self.profilePreset(forTitle: title) {
            configure(exactColors: exactPreset.colors, locations: exactPreset.locations)
            return
        }

        guard let palette = FragranceProfileText.profileColorPalette(forTitle: title) else {
            configure(families: fallbackFamilies)
            return
        }

        configure(
            exactColors: [
                UIColor(hex: palette.accentHex),
                UIColor(hex: palette.primaryHex),
                UIColor(hex: palette.baseHex)
            ],
            locations: [0.20, NSNumber(value: palette.primaryLocation), 1.00]
        )
    }

    static func profilePreset(forTitle title: String) -> (colors: [UIColor], locations: [NSNumber])? {
        guard let preset = TasteProfileGradientPreset.preset(forTitle: title) else { return nil }
        return (colors: preset.colors, locations: preset.locations)
    }

    func configure(exactColors colors: [UIColor], locations: [NSNumber] = [0.20, 0.45, 1.00]) {
        self.colors = colors
        self.locations = locations.map { CGFloat(truncating: $0) }
        centerPoint = CGPoint(x: 0.5, y: 0.04)
        setNeedsDisplay()
    }

    func setCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        setNeedsDisplay()
    }
}

extension UIColor {
    func softened(amount: CGFloat) -> UIColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return self }
        let mix = max(0, min(1, amount))
        return UIColor(
            red: r + (1 - r) * mix,
            green: g + (1 - g) * mix,
            blue: b + (1 - b) * mix,
            alpha: a
        )
    }
}
