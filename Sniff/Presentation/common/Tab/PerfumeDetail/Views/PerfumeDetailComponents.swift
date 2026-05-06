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
        $0.spacing = 16
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(concentration: String?, longevity: String?, sillage: String?) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.addArrangedSubview(makeRatingSection(
            title: "농도",
            info: UsageInfoMapper.concentrationInfo(for: concentration)
        ))
        stackView.addArrangedSubview(makeRatingSection(
            title: AppStrings.UIKitScreens.PerfumeDetail.longevity,
            info: UsageInfoMapper.longevityInfo(for: longevity)
        ))
        stackView.addArrangedSubview(makeRatingSection(
            title: AppStrings.UIKitScreens.PerfumeDetail.sillage,
            info: UsageInfoMapper.sillageInfo(for: sillage)
        ))
    }

    private func makeRatingHeader(title: String, value: String) -> UIView {
        let row = UIView()
        let headerLabel = UILabel().then {
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.numberOfLines = 1
            $0.lineBreakMode = .byTruncatingTail
        }

        let text = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: PerfumeDetailViewController.Palette.textPrimary
            ]
        )
        text.append(NSAttributedString(
            string: "  |  \(value)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: PerfumeDetailViewController.Palette.textSecondary
            ]
        ))
        headerLabel.attributedText = text

        row.addSubview(headerLabel)
        headerLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        return row
    }

    private func makeRatingSection(title: String, info: UsageInfoMapper.RatingInfo) -> UIView {
        let sectionStack = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 8
        }

        sectionStack.addArrangedSubview(makeRatingHeader(title: title, value: info.label))

        if info.rating > 0 {
            let ratingRow = UIStackView().then {
                $0.axis = .horizontal
                $0.alignment = .center
                $0.spacing = 10
            }
            ratingRow.addArrangedSubview(makeStarRatingView(rating: info.rating))
            ratingRow.addArrangedSubview(UILabel().then {
                $0.text = "\(info.rating) / 5"
                $0.font = .systemFont(ofSize: 13, weight: .medium)
                $0.textColor = PerfumeDetailViewController.Palette.textSecondary
            })
            sectionStack.addArrangedSubview(ratingRow)
        }

        return sectionStack
    }

    private func makeStarRatingView(rating: Int) -> UIStackView {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let stack = UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 3
        }

        (1...5).forEach { index in
            let imageName = index <= rating ? "star.fill" : "star.fill"
            let imageView = UIImageView(image: UIImage(systemName: imageName, withConfiguration: symbolConfig))
            imageView.tintColor = index <= rating
                ? PerfumeDetailViewController.Palette.textPrimary
                : UIColor(hex: "#E8E8E8")
            imageView.contentMode = .scaleAspectFit
            imageView.snp.makeConstraints { $0.size.equalTo(18) }
            stack.addArrangedSubview(imageView)
        }

        return stack
    }
}

final class OwnedPerfumeInfoCardView: UIView {
    var onEditTapped: (() -> Void)?

    private let titleLabel = UILabel().then {
        $0.text = "내 보유 정보"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = PerfumeDetailViewController.Palette.textPrimary
    }

    private let editButton = UIButton(type: .system).then {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "pencil")
        configuration.imagePadding = 5
        configuration.title = "수정"
        configuration.baseForegroundColor = PerfumeDetailViewController.Palette.textSecondary
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        configuration.background.strokeColor = UIColor(hex: "#DDDDDD")
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 8
        $0.configuration = configuration
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
    }

    private let editCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .semibold)
        $0.textColor = PerfumeDetailViewController.Palette.textMuted
        $0.textAlignment = .right
    }

    private let rowsStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 10
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PerfumeDetailViewController.Palette.card
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.5
        layer.borderColor = PerfumeDetailViewController.Palette.textPrimary.cgColor

        [titleLabel, editCountLabel, editButton, rowsStackView].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(20)
        }

        editButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(34)
        }

        editCountLabel.snp.makeConstraints {
            $0.centerY.equalTo(editButton)
            $0.trailing.equalTo(editButton.snp.leading).offset(-8)
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }

        rowsStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-20)
        }

        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with perfume: CollectedPerfume?) {
        rowsStackView.arrangedSubviews.forEach {
            rowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        guard let perfume else {
            editCountLabel.text = nil
            editButton.isEnabled = false
            editButton.alpha = 0.4
            return
        }

        editCountLabel.text = "\(perfume.registrationEditCount)/\(CollectedPerfumeEditPolicy.maxRegistrationEditCount) 수정가능횟수"
        editButton.isEnabled = perfume.canEditRegistrationInfo
        editButton.alpha = perfume.canEditRegistrationInfo ? 1 : 0.4

        rowsStackView.addArrangedSubview(makeChipRow(
            title: "사용 상태",
            value: perfume.usageStatus?.displayName ?? "-"
        ))
        rowsStackView.addArrangedSubview(makeChipRow(
            title: "사용 빈도",
            value: perfume.usageFrequency?.displayName ?? "-"
        ))
        rowsStackView.addArrangedSubview(makeChipRow(
            title: "취향 강도",
            value: perfume.preferenceLevel?.displayName ?? "-"
        ))
        rowsStackView.addArrangedSubview(makeMemoRow(memo: perfume.memo))
    }

    private func makeChipRow(title: String, value: String) -> UIView {
        let row = UIStackView().then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 14
        }

        row.addArrangedSubview(makeTitleLabel(title))
        row.addArrangedSubview(makeValueChip(value))
        row.addArrangedSubview(UIView())
        return row
    }

    private func makeMemoRow(memo: String?) -> UIView {
        let row = UIStackView().then {
            $0.axis = .horizontal
            $0.alignment = .top
            $0.spacing = 14
        }

        let trimmedMemo = memo?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let memoText = trimmedMemo.isEmpty ? "메모 없음" : trimmedMemo
        let memoLabel = UILabel().then {
            $0.text = memoText
            $0.font = .italicSystemFont(ofSize: 14)
            $0.textColor = PerfumeDetailViewController.Palette.textSecondary
            $0.numberOfLines = 0
        }

        row.addArrangedSubview(makeTitleLabel("메모"))
        row.addArrangedSubview(memoLabel)
        return row
    }

    private func makeTitleLabel(_ title: String) -> UILabel {
        UILabel().then {
            $0.text = title
            $0.font = .systemFont(ofSize: 15, weight: .semibold)
            $0.textColor = PerfumeDetailViewController.Palette.textMuted
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.snp.makeConstraints { $0.width.equalTo(72) }
        }
    }

    private func makeValueChip(_ value: String) -> UIView {
        let label = InsetLabel(contentInsets: UIEdgeInsets(top: 5, left: 14, bottom: 5, right: 14))
        label.text = value
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(hex: "#8A6F55")
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex: "#F1E8DF")
        label.layer.cornerRadius = 8
        label.layer.cornerCurve = .continuous
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor(hex: "#D8C5B4").cgColor
        label.clipsToBounds = true
        return label
    }

    @objc private func editTapped() {
        onEditTapped?()
    }
}

private final class InsetLabel: UILabel {
    private let contentInsets: UIEdgeInsets

    init(contentInsets: UIEdgeInsets) {
        self.contentInsets = contentInsets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let baseSize = super.intrinsicContentSize
        return CGSize(
            width: baseSize.width + contentInsets.left + contentInsets.right,
            height: baseSize.height + contentInsets.top + contentInsets.bottom
        )
    }
}

private enum UsageInfoMapper {
    struct RatingInfo {
        let label: String
        let rating: Int
    }

    static func concentrationInfo(for rawValue: String?) -> RatingInfo {
        switch normalize(rawValue) {
        case "perfume", "parfum", "extrait de parfum":
            return RatingInfo(label: "퍼퓸 · 6~12시간 지속", rating: 5)
        case "eau de parfum", "edp":
            return RatingInfo(label: "오 드 퍼퓸 · 4~6시간 지속", rating: 4)
        case "eau de toilette", "edt":
            return RatingInfo(label: "오 드 뚜왈렛 · 2~4시간 지속", rating: 3)
        case "eau de cologne", "edc":
            return RatingInfo(label: "오 드 코롱 · 1~2시간 지속", rating: 2)
        case "eau fraiche":
            return RatingInfo(label: "오 프레시 · 30분~1시간 지속", rating: 1)
        default:
            return RatingInfo(label: "정보 없음", rating: 0)
        }
    }

    static func longevityInfo(for rawValue: String?) -> RatingInfo {
        switch normalize(rawValue) {
        case "very long lasting":
            return RatingInfo(label: "매우 오래 지속됨", rating: 5)
        case "long lasting":
            return RatingInfo(label: "오래 지속됨", rating: 4)
        case "moderate":
            return RatingInfo(label: "보통", rating: 3)
        case "weak":
            return RatingInfo(label: "약함", rating: 2)
        case "poor":
            return RatingInfo(label: "매우 약함", rating: 1)
        default:
            return RatingInfo(label: "정보 없음", rating: 0)
        }
    }

    static func sillageInfo(for rawValue: String?) -> RatingInfo {
        switch normalize(rawValue) {
        case "enormous":
            return RatingInfo(label: "매우 강함", rating: 5)
        case "strong":
            return RatingInfo(label: "강함", rating: 4)
        case "moderate":
            return RatingInfo(label: "보통", rating: 3)
        case "soft":
            return RatingInfo(label: "은은함", rating: 2)
        case "intimate":
            return RatingInfo(label: "가까이서만", rating: 1)
        default:
            return RatingInfo(label: "정보 없음", rating: 0)
        }
    }

    private static func normalize(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .lowercased() ?? ""
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

final class ScentFamilyListView: UIView {
    struct Item {
        let rawValue: String
        let displayName: String
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 18
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(accords: [Item]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let visibleAccords = accords.isEmpty
            ? [Item(rawValue: "", displayName: "-")]
            : accords

        visibleAccords.forEach { item in
            stackView.addArrangedSubview(makeRow(for: item))
        }
    }

    private func makeRow(for item: Item) -> UIView {
        let row = UIStackView().then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 10
        }

        let dotView = UIView().then {
            $0.backgroundColor = item.rawValue.isEmpty
                ? PerfumeDetailViewController.Palette.textMuted
                : ScentFamilyColor.color(for: item.rawValue)
            $0.layer.cornerRadius = 5
            $0.snp.makeConstraints { $0.size.equalTo(10) }
        }

        let label = UILabel().then {
            $0.text = item.displayName
            $0.font = .systemFont(ofSize: 16, weight: .semibold)
            $0.textColor = PerfumeDetailViewController.Palette.textPrimary
            $0.numberOfLines = 1
            $0.lineBreakMode = .byTruncatingTail
        }

        row.addArrangedSubview(dotView)
        row.addArrangedSubview(label)
        return row
    }
}

final class NoteLineView: UIView {
    init(title: String, notes: [String]) {
        super.init(frame: .zero)

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = UIFont(name: "Georgia", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
            $0.textColor = PerfumeDetailViewController.Palette.textPrimary
        }

        let notesLabel = UILabel().then {
            $0.text = notes.isEmpty ? "-" : notes.joined(separator: ", ")
            $0.font = UIFont(name: "Georgia", size: 16) ?? .systemFont(ofSize: 16, weight: .regular)
            $0.textColor = PerfumeDetailViewController.Palette.textSecondary
            $0.numberOfLines = 0
        }

        [titleLabel, notesLabel].forEach { addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.leading.top.equalToSuperview()
            $0.width.equalTo(58)
        }
        notesLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(12)
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

    func configure(texts: [String]) {
        visibleTexts = Array(texts.prefix(2))
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
