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
        s.spacing = 8
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
        profileStack.spacing = 2

        let topRow = UIStackView(arrangedSubviews: [iconView, profileStack])
        topRow.axis = .horizontal
        topRow.spacing = 12
        topRow.alignment = .top

        let hintRow = UIStackView(arrangedSubviews: [hintDot, hintLabel])
        hintRow.axis = .horizontal
        hintRow.spacing = 6
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
            $0.top.equalTo(topRow.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(0.5)
        }
        barsStack.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(18)
        }
        hintDot.snp.makeConstraints { $0.size.equalTo(CGSize(width: 8, height: 8)) }
        hintRow.snp.makeConstraints {
            $0.top.equalTo(barsStack.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(18)
        }
        analysisLabel.snp.makeConstraints {
            $0.top.equalTo(hintRow.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(18)
            $0.bottom.equalToSuperview().inset(18)
        }
    }

        // MARK: - Configure

    func configure(with profile: UserTasteProfile, collectionCount: Int, tastingCount: Int) {
        iconView.backgroundColor = ScentFamilyColor.iconBackground(for: profile.displayLeadingFamily)
        iconLabel.text = ScentFamilyColor.iconEmoji(for: profile.displayLeadingFamily)
        profileNameLabel.text = profile.displayTitle
        profileSubLabel.text = profile.displayFamilySummary
        profileSubLabel.isHidden = profile.displayFamilySummary.isEmpty

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
                hintIntro = AppStrings.DomainDisplay.TasteProfile.needsCollectionOrRecord
                hintDot.backgroundColor = UIColor(hex: "#E24B4A")

            case .onboardingCollection:
                hintIntro = AppStrings.DomainDisplay.TasteProfile.needsTastingRecord
                hintDot.backgroundColor = UIColor(hex: "#EF9F27")

            case .earlyTasting, .heavyTasting:
                let parts = [
                    tastingCount > 0 ? AppStrings.DomainDisplay.TasteProfile.tastingCount(tastingCount) : nil,
                    collectionCount > 0 ? AppStrings.DomainDisplay.TasteProfile.collectionCount(collectionCount) : nil
                ].compactMap { $0 }.joined(separator: " · ")
                hintIntro = parts.isEmpty
                ? AppStrings.DomainDisplay.TasteProfile.updatedFromTasting
                : AppStrings.DomainDisplay.TasteProfile.updatedFrom(parts)
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
            return AppStrings.DomainDisplay.TasteProfile.prefersTwo(first, trimmed[1])
        }

        return AppStrings.DomainDisplay.TasteProfile.prefersOne(first)
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
