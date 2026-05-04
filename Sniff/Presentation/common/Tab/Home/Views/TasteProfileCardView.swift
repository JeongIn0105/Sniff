//
//  TasteProfileCardView.swift
//  Sniff
//

import UIKit
import SnapKit

final class TasteProfileCardView: UIView {

    private enum Color {
        static let textPrimary = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
        static let textLabel = UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1)
        static let textPercent = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        static let textDescription = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1)
        static let textMuted = UIColor(red: 0.60, green: 0.60, blue: 0.60, alpha: 1)
    }

    private let iconView = TasteProfileGradientIconView()

    private let profileNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = Color.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let profileSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = Color.textLabel
        label.numberOfLines = 1
        return label
    }()

    private let chipStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        return stack
    }()

    private let analysisLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Color.textDescription
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor

        [iconView, profileNameLabel, profileSubtitleLabel, chipStackView, analysisLabel].forEach { addSubview($0) }
        iconView.setCornerRadius(8)

        iconView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.size.equalTo(CGSize(width: 36, height: 36))
        }

        profileNameLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconView)
            $0.leading.equalTo(iconView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(20)
        }

        profileSubtitleLabel.snp.makeConstraints {
            $0.top.equalTo(profileNameLabel.snp.bottom).offset(6)
            $0.leading.equalTo(profileNameLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        chipStackView.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        analysisLabel.snp.makeConstraints {
            $0.top.equalTo(chipStackView.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
        }
    }

    func configure(with profile: UserTasteProfile, collectionCount: Int, tastingCount: Int) {
        let topFamilies = Array(profile.displayFamilies.prefix(3))
        iconView.configure(title: profile.displayTitle, fallbackFamilies: topFamilies)
        profileNameLabel.text = profile.displayTitle
        profileSubtitleLabel.text = profile.displayMajorSummary

        chipStackView.arrangedSubviews.forEach {
            chipStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let majorFamilies = majorFamilyRatios(from: profile.scentVector)
        let highlightedFamilies = Set(
            majorFamilies
                .sorted { lhs, rhs in
                    if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                    return lhs.0 < rhs.0
                }
                .prefix(2)
                .filter { $0.1 > 0 }
                .map(\.0)
        )

        for (family, ratio) in majorFamilies {
            chipStackView.addArrangedSubview(
                makeBarRow(
                    family: family,
                    ratio: ratio,
                    color: ScentFamilyColor.barColor(for: family),
                    isHighlighted: highlightedFamilies.contains(family)
                )
            )
        }

        analysisLabel.text = makeAnalysisText(
            for: profile,
            collectionCount: collectionCount,
            tastingCount: tastingCount
        )
    }

    private func makeAnalysisText(
        for profile: UserTasteProfile,
        collectionCount: Int,
        tastingCount: Int
    ) -> String {
        let summary = profile.analysisSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty {
            return summary
        }

        let parts = [
            tastingCount > 0 ? AppStrings.DomainDisplay.TasteProfile.tastingCount(tastingCount) : nil,
            collectionCount > 0 ? AppStrings.DomainDisplay.TasteProfile.collectionCount(collectionCount) : nil
        ]
        .compactMap { $0 }
        .joined(separator: ", ")

        if !parts.isEmpty {
            return "\(parts)을 기반으로 취향을 정리했어요."
        }

        let safeStartingPoint = profile.safeStartingPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        if !safeStartingPoint.isEmpty {
            return safeStartingPoint
        }

        return AppStrings.DomainDisplay.TasteProfile.needsCollectionOrRecord
    }

    private func makeBarRow(family: String, ratio: Double, color: UIColor, isHighlighted: Bool) -> UIView {
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = Color.textLabel
        nameLabel.text = family

        let dotView = UIView()
        dotView.backgroundColor = color
        dotView.layer.cornerRadius = 4.5

        let trackView = UIView()
        trackView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1)
        trackView.layer.cornerRadius = 4
        trackView.clipsToBounds = true

        let fillView = UIView()
        fillView.backgroundColor = color
        fillView.layer.cornerRadius = 4
        trackView.addSubview(fillView)

        let valueLabel = UILabel()
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = isHighlighted ? Color.textPercent : Color.textMuted
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = false
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.text = "\(Int((ratio * 100).rounded()))%"

        let row = UIView()
        [dotView, nameLabel, trackView, valueLabel].forEach { row.addSubview($0) }

        dotView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(5)
            $0.size.equalTo(CGSize(width: 9, height: 9))
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(dotView.snp.trailing).offset(8)
            $0.top.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-12)
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(trackView)
            $0.width.equalTo(43)
        }

        trackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalTo(valueLabel.snp.leading).offset(-12)
            $0.height.equalTo(8)
            $0.bottom.equalToSuperview()
        }

        fillView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(max(ratio, 0.02))
        }

        return row
    }

    private func majorFamilyRatios(from scentVector: [String: Double]) -> [(String, Double)] {
        let grouped = scentVector.reduce(into: [String: Double]()) { result, pair in
            guard let majorFamily = majorFamily(for: pair.key) else { return }
            result[majorFamily, default: 0] += pair.value
        }

        let order = ["플로럴", "앰버", "우디", "프레쉬"]
        return order.map { family in
            (family, grouped[family, default: 0])
        }
    }

    private func majorFamily(for family: String) -> String? {
        switch family {
        case "Floral", "Soft Floral", "Floral Amber":
            return "플로럴"
        case "Soft Amber", "Amber", "Woody Amber":
            return "앰버"
        case "Woods", "Mossy Woods", "Dry Woods":
            return "우디"
        case "Citrus", "Fruity", "Green", "Water", "Aromatic":
            return "프레쉬"
        default:
            return nil
        }
    }
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
        let baseBeige = UIColor(red: 0xF1/255.0, green: 0xE8/255.0, blue: 0xDF/255.0, alpha: 1)

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
        switch title {
        case "상큼하고 활기찬 취향":
            return (
                colors: [
                    UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1),
                    UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        case "맑고 세련된 취향":
            return (
                colors: [
                    UIColor(red: 0.97, green: 0.94, blue: 0.80, alpha: 1),
                    UIColor(red: 0.73, green: 0.87, blue: 0.92, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.52, 1.00]
            )
        case "시원하고 신비로운 취향":
            return (
                colors: [
                    UIColor(red: 0.80, green: 0.75, blue: 0.83, alpha: 1),
                    UIColor(red: 0.60, green: 0.81, blue: 0.89, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        case "부드럽고 청순한 취향":
            return (
                colors: [
                    UIColor(red: 1.00, green: 0.56, blue: 0.53, alpha: 1),
                    UIColor(red: 0.94, green: 0.66, blue: 0.72, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        case "포근하고 여유로운 취향":
            return (
                colors: [
                    UIColor(red: 0.94, green: 0.66, blue: 0.72, alpha: 1),
                    UIColor(red: 0.82, green: 0.45, blue: 0.67, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        case "달콤하고 화사한 취향":
            return (
                colors: [
                    UIColor(red: 0.94, green: 0.48, blue: 0.75, alpha: 1),
                    UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        case "싱그럽고 자연스러운 취향":
            return (
                colors: [
                    UIColor(red: 0.60, green: 0.81, blue: 0.89, alpha: 1),
                    UIColor(red: 0.74, green: 0.87, blue: 0.66, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        case "짙고 시크한 취향":
            return (
                colors: [
                    UIColor(red: 0.75, green: 0.74, blue: 0.65, alpha: 1),
                    UIColor(red: 0.84, green: 0.73, blue: 0.59, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        case "짙고 강렬한 취향":
            return (
                colors: [
                    UIColor(red: 0.84, green: 0.65, blue: 0.52, alpha: 1),
                    UIColor(red: 0.75, green: 0.36, blue: 0.47, alpha: 1),
                    UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
                ],
                locations: [0.20, 0.45, 1.00]
            )
        default:
            return nil
        }
    }

    /// Figma Dev Mode 정확한 색상 배열과 locations로 그라디언트를 설정합니다.
    /// - Parameters:
    ///   - colors: [center, mid, edge] 순서의 UIColor 배열
    ///   - locations: CAGradientLayer.locations 값 (기본값: [0.20, 0.45, 1.00])
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
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
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
