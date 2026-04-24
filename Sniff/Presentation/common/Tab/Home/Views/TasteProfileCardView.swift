//
//  TasteProfileCardView.swift
//  Sniff
//

import UIKit
import SnapKit

final class TasteProfileCardView: UIView {

    private let iconView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()

    private let profileNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
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
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.label.withAlphaComponent(0.74)
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

        [iconView, profileNameLabel, chipStackView, analysisLabel].forEach { addSubview($0) }

        iconView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.size.equalTo(CGSize(width: 38, height: 38))
        }

        profileNameLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconView)
            $0.leading.equalTo(iconView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(20)
        }

        chipStackView.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        analysisLabel.snp.makeConstraints {
            $0.top.equalTo(chipStackView.snp.bottom).offset(26)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    func configure(with profile: UserTasteProfile, collectionCount: Int, tastingCount: Int) {
        iconView.backgroundColor = ScentFamilyColor.iconBackground(for: profile.displayLeadingFamily)
        profileNameLabel.text = profile.displayTitle

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
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .secondaryLabel
        nameLabel.text = family

        let dotView = UIView()
        dotView.backgroundColor = color
        dotView.layer.cornerRadius = 4

        let trackView = UIView()
        trackView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1)
        trackView.layer.cornerRadius = 4
        trackView.clipsToBounds = true

        let fillView = UIView()
        fillView.backgroundColor = color
        fillView.layer.cornerRadius = 4
        trackView.addSubview(fillView)

        let valueLabel = UILabel()
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = isHighlighted ? .label : .tertiaryLabel
        valueLabel.textAlignment = .right
        valueLabel.text = "\(Int((ratio * 100).rounded()))%"

        let row = UIView()
        [dotView, nameLabel, trackView, valueLabel].forEach { row.addSubview($0) }

        dotView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(4)
            $0.size.equalTo(CGSize(width: 8, height: 8))
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(dotView.snp.trailing).offset(8)
            $0.top.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-8)
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(nameLabel)
            $0.width.equalTo(40)
        }

        trackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview()
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
