//
//  PerfumeDetailComponents.swift
//  Sniff
//
//  Created by Codex on 2026.04.20.
//

import UIKit
import SnapKit
import Then

final class SectionContainerView: UIView {
    private let titleLabel = UILabel().then {
        $0.font = UIFont(name: "Georgia-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = PerfumeDetailViewController.Palette.textPrimary
    }
    private let divider = UIView().then {
        $0.backgroundColor = PerfumeDetailViewController.Palette.border
    }
    private let contentContainer = UIView()

    init(title: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = PerfumeDetailViewController.Palette.surface
        addSubview(divider)
        addSubview(contentContainer)

        divider.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        if let title {
            titleLabel.text = title
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.top.equalToSuperview().offset(14)
                $0.leading.trailing.equalToSuperview().inset(20)
            }
            contentContainer.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(12)
                $0.leading.trailing.equalToSuperview().inset(20)
                $0.bottom.equalToSuperview().offset(-14)
            }
        } else {
            contentContainer.snp.makeConstraints {
                $0.top.equalToSuperview().offset(18)
                $0.leading.trailing.equalToSuperview().inset(20)
                $0.bottom.equalToSuperview().offset(-18)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func embed(_ view: UIView) {
        contentContainer.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

final class UsageInfoView: UIView {
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(concentration: String, longevity: String, sillage: String) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.addArrangedSubview(makeRow(title: "농도", value: concentration))
        stackView.addArrangedSubview(makeRow(title: AppStrings.UIKitScreens.PerfumeDetail.longevity, value: longevity))
        stackView.addArrangedSubview(makeRow(title: AppStrings.UIKitScreens.PerfumeDetail.sillage, value: sillage))
    }

    private func makeRow(title: String, value: String) -> UIView {
        let row = UIView()
        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = UIFont(name: "Georgia", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = PerfumeDetailViewController.Palette.textSecondary
            $0.numberOfLines = 2
        }
        let valueLabel = UILabel().then {
            $0.text = value
            $0.font = UIFont(name: "Georgia-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
            $0.textColor = PerfumeDetailViewController.Palette.textPrimary
            $0.textAlignment = .right
        }

        [titleLabel, valueLabel].forEach { row.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalTo(54)
        }
        valueLabel.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
            $0.trailing.centerY.equalToSuperview()
        }
        return row
    }
}

final class DetailNotesView: UIView {
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 14
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(topNotes: [String], middleNotes: [String], baseNotes: [String]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.addArrangedSubview(NoteLineView(title: AppStrings.UIKitScreens.PerfumeDetail.topNotes, notes: topNotes))
        stackView.addArrangedSubview(NoteLineView(title: AppStrings.UIKitScreens.PerfumeDetail.middleNotes, notes: middleNotes))
        stackView.addArrangedSubview(NoteLineView(title: AppStrings.UIKitScreens.PerfumeDetail.baseNotes, notes: baseNotes))
    }
}

final class NoteLineView: UIView {
    init(title: String, notes: [String]) {
        super.init(frame: .zero)

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = UIFont(name: "Georgia", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = PerfumeDetailViewController.Palette.textSecondary
        }

        let labelWidth: CGFloat = 44
        let sectionInsets: CGFloat = 40
        let gap: CGFloat = 12
        let availableWidth = UIScreen.main.bounds.width - sectionInsets - labelWidth - gap

        let chipsView = ChipWrapView(style: .outline, maxWidth: availableWidth)
        chipsView.configure(
            texts: notes.isEmpty ? ["-"] : notes,
            highlightedIndices: Set<Int>(),
            colorPalette: PerfumeDetailViewController.Palette.self
        )

        [titleLabel, chipsView].forEach { addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.width.equalTo(labelWidth)
        }
        chipsView.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(gap)
            $0.top.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}

final class SeasonSelectionView: UIView {
    private let displayMap: [String: String] = [
        "spring": AppStrings.DomainDisplay.SearchFilters.spring,
        "summer": AppStrings.DomainDisplay.SearchFilters.summer,
        "fall": AppStrings.DomainDisplay.SearchFilters.fall,
        "winter": AppStrings.DomainDisplay.SearchFilters.winter
    ]
    private var visibleTexts: [String] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(selectedSeasons: [String]) {
        visibleTexts = Array(selectedSeasons.prefix(2)).map {
            displayMap[$0.lowercased()] ?? PerfumeKoreanTranslator.koreanSeason(for: $0)
        }
        subviews.forEach { $0.removeFromSuperview() }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.removeFromSuperview() }

        let spacing: CGFloat = 10
        var x: CGFloat = 0

        for text in visibleTexts {
            let width = chipWidth(for: text)
            let chip = makeChip(text: text)
            chip.frame = CGRect(x: x, y: 0, width: width, height: 36)
            addSubview(chip)
            x += width + spacing
        }
    }

    override var intrinsicContentSize: CGSize {
        let spacing: CGFloat = 10
        let totalWidth = visibleTexts.enumerated().reduce(CGFloat(0)) { partial, item in
            let spacingValue = item.offset == 0 ? CGFloat(0) : spacing
            return partial + spacingValue + chipWidth(for: item.element)
        }
        return CGSize(width: totalWidth, height: visibleTexts.isEmpty ? 0 : 36)
    }

    private func chipWidth(for text: String) -> CGFloat {
        let font = UIFont(name: "Georgia-Bold", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return ceil(textWidth) + 32
    }

    private func makeChip(text: String) -> UILabel {
        let chip = UILabel()
        chip.text = text
        chip.textAlignment = .center
        chip.font = UIFont(name: "Georgia-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
        chip.textColor = PerfumeDetailViewController.Palette.textPrimary
        chip.backgroundColor = PerfumeDetailViewController.Palette.card
        chip.layer.cornerRadius = 18
        chip.layer.borderWidth = 1
        chip.layer.borderColor = PerfumeDetailViewController.Palette.border.cgColor
        chip.clipsToBounds = true
        return chip
    }
}

final class ChipWrapView: UIView {
    enum Style {
        case outline
        case mixed
    }

    private let style: Style
    private let maxWidth: CGFloat
    private var texts: [String] = []
    private var highlightedIndices = Set<Int>()

    init(style: Style, maxWidth: CGFloat = UIScreen.main.bounds.width - 40) {
        self.style = style
        self.maxWidth = maxWidth
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(
        texts: [String],
        highlightedIndices: Set<Int>,
        colorPalette: PerfumeDetailViewController.Palette.Type
    ) {
        self.texts = texts
        self.highlightedIndices = highlightedIndices
        subviews.forEach { $0.removeFromSuperview() }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.removeFromSuperview() }

        var x: CGFloat = 0
        var y: CGFloat = 0
        let horizontalSpacing: CGFloat = 10
        let verticalSpacing: CGFloat = 8
        let height: CGFloat = 36

        for (index, text) in texts.enumerated() {
            let chip = makeChip(text: text, highlighted: highlightedIndices.contains(index))
            let width = chipWidth(for: text)

            if x + width > bounds.width && x > 0 {
                x = 0
                y += height + verticalSpacing
            }

            chip.frame = CGRect(x: x, y: y, width: width, height: height)
            addSubview(chip)
            x += width + horizontalSpacing
        }
    }

    override var intrinsicContentSize: CGSize {
        var x: CGFloat = 0
        var y: CGFloat = 0
        let horizontalSpacing: CGFloat = 10
        let verticalSpacing: CGFloat = 8
        let height: CGFloat = 36

        for text in texts {
            let width = chipWidth(for: text)
            if x + width > maxWidth && x > 0 {
                x = 0
                y += height + verticalSpacing
            }
            x += width + horizontalSpacing
        }

        return CGSize(width: UIView.noIntrinsicMetric, height: y + height)
    }

    private func makeChip(text: String, highlighted: Bool) -> UIView {
        let label = UILabel().then {
            $0.text = text
            $0.font = UIFont(name: "Georgia-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
            $0.textColor = highlighted
                ? PerfumeDetailViewController.Palette.textPrimary
                : PerfumeDetailViewController.Palette.textSecondary
        }

        let container = UIView()
        container.backgroundColor = PerfumeDetailViewController.Palette.card
        container.layer.cornerRadius = 18
        container.layer.borderWidth = 1
        container.layer.borderColor = PerfumeDetailViewController.Palette.border.cgColor
        container.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        return container
    }

    private func chipWidth(for text: String) -> CGFloat {
        let font = UIFont(name: "Georgia-Bold", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return ceil(textWidth) + 32
    }
}
