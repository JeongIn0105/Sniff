//
//  TasteProfileCardView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.16.
//

    //
    //  TasteProfileCardView.swift
    //  Sniff
    //

import UIKit
import SnapKit

    // MARK: - ScentFamilyColor

private enum ScentFamilyColor {
    static func barColor(for family: String) -> UIColor {
        switch family {
            case "Floral", "Soft Floral":           return UIColor(hex: "#e8a4b8")
            case "Amber", "Woody Amber":            return UIColor(hex: "#c8782a")
            case "Woody", "Dry Woods", "Mossy Woods": return UIColor(hex: "#a07850")
            case "Fresh", "Citrus", "Water":        return UIColor(hex: "#7ecbb8")
            case "Aquatic":                         return UIColor(hex: "#4a90b8")
            case "Spicy", "Aromatic":               return UIColor(hex: "#9a3a4a")
            case "Musk":                            return UIColor(hex: "#9FB8C4")
            case "Fruity", "Green":                 return UIColor(hex: "#8fba5a")
            default:                                return UIColor(hex: "#b0a898")
        }
    }

    static func iconBackground(for profileCode: String) -> UIColor {
        switch profileCode {
            case "P1", "P2":        return UIColor(hex: "#E1F5EE")
            case "P3", "P4":        return UIColor(hex: "#FBEAF0")
            case "P5", "P6":        return UIColor(hex: "#FAEEDA")
            case "P7", "P8":        return UIColor(hex: "#EEEDFE")
            default:                return UIColor(hex: "#F1EFE8")
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
            default:   return "✨"
        }
    }
}

    // MARK: - TasteProfileCardView

final class TasteProfileCardView: UIView {

        // MARK: - UI

    private let iconView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 13
        v.layer.masksToBounds = true
        return v
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22)
        l.textAlignment = .center
        return l
    }()

    private let profileNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textColor = .label
        l.numberOfLines = 1
        l.adjustsFontSizeToFitWidth = true
        return l
    }()

    private let profileSubLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        return l
    }()

    private let divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
        return v
    }()

    private let barsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        return s
    }()

    private let hintDot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        return v
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        return l
    }()

    private let analysisLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }()

        // MARK: - Init

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
        layer.cornerRadius = 14
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor

        let profileStack = UIStackView(arrangedSubviews: [profileNameLabel, profileSubLabel])
        profileStack.axis = .vertical
        profileStack.spacing = 3

        let topRow = UIStackView(arrangedSubviews: [iconView, profileStack])
        topRow.axis = .horizontal
        topRow.spacing = 14
        topRow.alignment = .top

        let hintRow = UIStackView(arrangedSubviews: [hintDot, hintLabel])
        hintRow.axis = .horizontal
        hintRow.spacing = 7
        hintRow.alignment = .center

        [topRow, divider, barsStack, hintRow, analysisLabel].forEach { addSubview($0) }
        iconView.addSubview(iconLabel)

        topRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(18)
        }
        iconView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 46, height: 46))
        }
        iconLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        divider.snp.makeConstraints {
            $0.top.equalTo(topRow.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(0.5)
        }
        barsStack.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(18)
        }
        hintDot.snp.makeConstraints { $0.size.equalTo(CGSize(width: 8, height: 8)) }
        hintRow.snp.makeConstraints {
            $0.top.equalTo(barsStack.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(18)
        }
        analysisLabel.snp.makeConstraints {
            $0.top.equalTo(hintRow.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.bottom.equalToSuperview().inset(18)
        }
    }

        // MARK: - Configure

    func configure(with profile: UserTasteProfile, collectionCount: Int, tastingCount: Int) {
        iconView.backgroundColor = ScentFamilyColor.iconBackground(for: profile.primaryProfileCode)
        iconLabel.text = ScentFamilyColor.iconEmoji(for: profile.primaryProfileCode)
        profileNameLabel.text = profile.primaryProfileName
        profileSubLabel.text = nil
        profileSubLabel.isHidden = true

        configureHint(
            profile: profile,
            collectionCount: collectionCount,
            tastingCount: tastingCount
        )
        configureAnalysisText(for: profile)

        configureBars(from: profile.scentVector)
    }

        // MARK: - Private

    private func configureHint(
        profile: UserTasteProfile,
        collectionCount: Int,
        tastingCount: Int
    ) {
        let hintIntro: String
        switch profile.stage {
            case .onboardingOnly:
                hintIntro = "향수를 등록하거나 시향 기록을 남기면 취향이 더 선명해져요"
                hintDot.backgroundColor = UIColor(hex: "#E24B4A")

            case .onboardingCollection:
                hintIntro = "시향 기록을 남기면 취향이 더 정확해져요"
                hintDot.backgroundColor = UIColor(hex: "#EF9F27")

            case .earlyTasting, .heavyTasting:
                let parts = [
                    tastingCount > 0 ? "시향 기록 \(tastingCount)개" : nil,
                    collectionCount > 0 ? "보유 향수 \(collectionCount)개" : nil
                ].compactMap { $0 }.joined(separator: " · ")
                hintIntro = parts.isEmpty
                ? "시향 기록 기반으로 업데이트됐어요"
                : "\(parts) 기반으로 취향이 업데이트됐어요"
                hintDot.backgroundColor = UIColor(hex: "#5DCAA5")
        }

        hintLabel.text = hintIntro
    }

    private func configureAnalysisText(for profile: UserTasteProfile) {
        analysisLabel.text = makeAnalysisText(for: profile)
    }

    private func makeAnalysisText(for profile: UserTasteProfile) -> String? {
        let summary = profile.analysisSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summary.isEmpty {
            return summary
        }

        let safeStartingPoint = profile.safeStartingPoint.trimmingCharacters(in: .whitespacesAndNewlines)
        if !safeStartingPoint.isEmpty {
            return safeStartingPoint
        }

        return makeImpressionLine(from: profile.preferredImpressions)
    }

    private func makeImpressionLine(from impressions: [String]) -> String? {
        let trimmed = impressions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let first = trimmed.first else { return nil }

        if trimmed.count >= 2 {
            return "사용자님은 \(first) 분위기와 \(trimmed[1]) 분위기를 선호해요"
        }

        return "사용자님은 \(first) 분위기를 선호해요"
    }

    private func configureBars(from scentVector: [String: Double]) {
        barsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let top4 = scentVector
            .sorted { $0.value > $1.value }
            .prefix(4)

        for (family, ratio) in top4 {
            let row = makeBarRow(
                family: family,
                ratio: ratio,
                color: ScentFamilyColor.barColor(for: family)
            )
            barsStack.addArrangedSubview(row)
        }
    }

    private func makeBarRow(
        family: String,
        ratio: Double,
        color: UIColor
    ) -> UIView {
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textColor = .secondaryLabel
        nameLabel.text = family

        let track = UIView()
        track.backgroundColor = UIColor.systemFill
        track.layer.cornerRadius = 3.5
        track.clipsToBounds = true

        let fill = UIView()
        fill.backgroundColor = color
        fill.layer.cornerRadius = 3.5
        track.addSubview(fill)

        let pctLabel = UILabel()
        pctLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        pctLabel.textColor = .tertiaryLabel
        pctLabel.text = "\(Int((ratio * 100).rounded()))%"
        pctLabel.textAlignment = .right

        let row = UIView()
        [nameLabel, track, pctLabel].forEach { row.addSubview($0) }

        nameLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.width.equalTo(78)
        }
        pctLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.width.equalTo(32)
        }
        track.snp.makeConstraints {
            $0.leading.equalTo(nameLabel.snp.trailing).offset(10)
            $0.trailing.equalTo(pctLabel.snp.leading).offset(-10)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(7)
        }
        fill.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(max(ratio, 0.02))
        }
        row.snp.makeConstraints { $0.height.equalTo(20) }

        return row
    }
}

    // MARK: - UIColor hex 확장

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
