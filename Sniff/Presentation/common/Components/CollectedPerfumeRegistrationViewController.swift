//
//  CollectedPerfumeRegistrationViewController.swift
//  Sniff
//
//  Created by Codex on 2026.05.04.
//

import UIKit
import Kingfisher

final class CollectedPerfumeRegistrationViewController: UIViewController {

    private enum ContentTab {
        case perfumeInfo
        case directInput
    }

    var onRegister: ((CollectedPerfumeRegistrationInfo) -> Void)?
    var onRetrySearch: (() -> Void)?

    private let perfume: Perfume

    private let statusControl = UISegmentedControl(items: CollectedPerfumeUsageStatus.allCases.map(\.displayName))
    private let frequencyControl = UISegmentedControl(items: CollectedPerfumeUsageFrequency.allCases.map(\.displayName))
    private let preferenceControl = UISegmentedControl(items: CollectedPerfumePreferenceLevel.allCases.map(\.displayName))
    private let memoTextView = UITextView()
    private let perfumeImageView = UIImageView()
    private let perfumeInfoChipButton = UIButton(type: .system)
    private let directInputChipButton = UIButton(type: .system)
    private let perfumeInfoContentStack = UIStackView()
    private let directInputContentStack = UIStackView()
    private let registerButton = UIButton(type: .system)

    init(perfume: Perfume) {
        self.perfume = perfume
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = ""

        statusControl.selectedSegmentIndex = 0
        frequencyControl.selectedSegmentIndex = 1
        preferenceControl.selectedSegmentIndex = 0
        [statusControl, frequencyControl, preferenceControl].forEach(configureSegmentedControl)

        configureContentStacks()
        configureTabButtons()
        configureRegisterButton()

        memoTextView.font = .systemFont(ofSize: 15)
        memoTextView.layer.cornerRadius = 12
        memoTextView.layer.borderWidth = 1
        memoTextView.layer.borderColor = UIColor.systemGray5.cgColor
        memoTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        memoTextView.heightAnchor.constraint(equalToConstant: 150).isActive = true

        let tabStack = UIStackView(arrangedSubviews: [perfumeInfoChipButton, directInputChipButton])
        tabStack.axis = .horizontal
        tabStack.spacing = 8
        tabStack.distribution = .fillEqually
        tabStack.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let stack = UIStackView(arrangedSubviews: [
            makeHeaderView(),
            makePerfumeCard(),
            tabStack,
            perfumeInfoContentStack,
            directInputContentStack
        ])
        stack.axis = .vertical
        stack.spacing = 22
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let bottomContainer = UIView()
        bottomContainer.backgroundColor = .systemBackground
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(registerButton)
        registerButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(bottomContainer)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            registerButton.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 12),
            registerButton.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            registerButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            registerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            registerButton.heightAnchor.constraint(equalToConstant: 54)
        ])

        configurePerfumeInfoContent()
        configureDirectInputContent()
        updateSelectedTab(.directInput)
    }

    private func makePerfumeCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(hex: "#F7F7FA")
        container.layer.cornerRadius = 16
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray5.cgColor
        perfumeImageView.contentMode = .scaleAspectFit
        perfumeImageView.backgroundColor = .systemBackground
        perfumeImageView.layer.cornerRadius = 12
        perfumeImageView.clipsToBounds = true
        if let imageUrl = perfume.imageUrl, let url = URL(string: imageUrl) {
            perfumeImageView.kf.setImage(with: url)
        }

        let brandLabel = UILabel()
        brandLabel.text = PerfumePresentationSupport.displayBrand(perfume.brand)
        brandLabel.font = .systemFont(ofSize: 13, weight: .medium)
        brandLabel.textColor = .secondaryLabel

        let nameLabel = UILabel()
        nameLabel.text = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 2

        let retryButton = UIButton(type: .system)
        var retryButtonTitle = AttributedString("다시 검색")
        retryButtonTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        var retryConfiguration = UIButton.Configuration.plain()
        retryConfiguration.attributedTitle = retryButtonTitle
        retryConfiguration.baseForegroundColor = .label
        retryConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        retryConfiguration.background.backgroundColor = UIColor(hex: "#F1ECE6")
        retryConfiguration.background.cornerRadius = 12
        retryButton.configuration = retryConfiguration
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        let labelStack = UIStackView(arrangedSubviews: [brandLabel, nameLabel, retryButton])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.alignment = .leading

        [perfumeImageView, labelStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([
            perfumeImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            perfumeImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            perfumeImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            perfumeImageView.widthAnchor.constraint(equalToConstant: 72),
            perfumeImageView.heightAnchor.constraint(equalToConstant: 88),

            labelStack.leadingAnchor.constraint(equalTo: perfumeImageView.trailingAnchor, constant: 16),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -16),
            labelStack.centerYAnchor.constraint(equalTo: perfumeImageView.centerYAnchor)
        ])

        return container
    }

    private func makeHeaderView() -> UIView {
        let container = UIView()

        let backButton = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: configuration), for: .normal)
        backButton.tintColor = .label
        backButton.contentHorizontalAlignment = .leading
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        let titleLabel = UILabel()
        titleLabel.text = "보유 향수 등록"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        [backButton, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            backButton.topAnchor.constraint(equalTo: container.topAnchor),
            backButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])

        return container
    }

    private func configureContentStacks() {
        [perfumeInfoContentStack, directInputContentStack].forEach {
            $0.axis = .vertical
            $0.spacing = 20
        }
    }

    private func configureSegmentedControl(_ control: UISegmentedControl) {
        control.selectedSegmentTintColor = .systemBackground
        control.backgroundColor = UIColor(hex: "#EFEFF1")
        control.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.label
        ], for: .normal)
        control.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor.label
        ], for: .selected)
        control.heightAnchor.constraint(equalToConstant: 46).isActive = true
    }

    private func configureTabButtons() {
        perfumeInfoChipButton.setTitle("향수 정보", for: .normal)
        directInputChipButton.setTitle("직접 입력할 정보", for: .normal)
        perfumeInfoChipButton.addTarget(self, action: #selector(perfumeInfoTabTapped), for: .touchUpInside)
        directInputChipButton.addTarget(self, action: #selector(directInputTabTapped), for: .touchUpInside)
    }

    private func configureRegisterButton() {
        registerButton.setTitle("등록하기", for: .normal)
        registerButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        registerButton.backgroundColor = UIColor(hex: "#1F1F1F")
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 14
        registerButton.layer.cornerCurve = .continuous
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
    }

    private func configurePerfumeInfoContent() {
        perfumeInfoContentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        perfumeInfoContentStack.addArrangedSubview(makeInfoSection(
            title: "사용 정보",
            rows: [
                ("농도", PerfumePresentationSupport.displayConcentration(perfume.concentration)),
                ("지속력", PerfumePresentationSupport.displayLongevity(perfume.longevity)),
                ("확산력", PerfumePresentationSupport.displaySillage(perfume.sillage))
            ]
        ))

        perfumeInfoContentStack.addArrangedSubview(makeChipSection(
            title: "향 계열",
            values: PerfumePresentationSupport.displayAccords(perfume.mainAccords)
        ))

        perfumeInfoContentStack.addArrangedSubview(makeInfoSection(
            title: "노트",
            rows: [
                (AppStrings.UIKitScreens.PerfumeDetail.topNotes, joinedNotes(perfume.topNotes)),
                (AppStrings.UIKitScreens.PerfumeDetail.middleNotes, joinedNotes(perfume.middleNotes)),
                (AppStrings.UIKitScreens.PerfumeDetail.baseNotes, joinedNotes(perfume.baseNotes))
            ]
        ))

        perfumeInfoContentStack.addArrangedSubview(makeChipSection(
            title: "계절",
            values: displaySeasons(for: perfume)
        ))
    }

    private func configureDirectInputContent() {
        directInputContentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        directInputContentStack.addArrangedSubview(makeSectionTitle("직접 입력할 정보"))
        directInputContentStack.addArrangedSubview(makeField(title: "사용 상태", control: statusControl))
        directInputContentStack.addArrangedSubview(makeField(title: "사용 빈도", control: frequencyControl))
        directInputContentStack.addArrangedSubview(makeField(title: "내 취향 정도", control: preferenceControl))
        directInputContentStack.addArrangedSubview(makeMemoField())
    }

    private func makeInfoSection(title: String, rows: [(String, String)]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

        stack.addArrangedSubview(makeSectionTitle(title))
        rows.forEach { title, value in
            stack.addArrangedSubview(makeInfoRow(title: title, value: value))
        }
        return stack
    }

    private func makeChipSection(title: String, values: [String]) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.addArrangedSubview(makeSectionTitle(title))
        stack.addArrangedSubview(RegistrationChipWrapView(values: values.isEmpty ? ["-"] : values))
        return stack
    }

    private func makeInfoRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .medium)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.alignment = .firstBaseline
        row.spacing = 16
        return row
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }

    private func makeField(title: String, control: UISegmentedControl) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label

        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func makeMemoField() -> UIStackView {
        let label = UILabel()
        label.text = "메모"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label

        let stack = UIStackView(arrangedSubviews: [label, memoTextView])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func joinedNotes(_ notes: [String]?) -> String {
        let displayNotes = PerfumePresentationSupport.displayNotes(notes ?? [])
        return displayNotes.isEmpty ? "-" : displayNotes.joined(separator: ", ")
    }

    private func displaySeasons(for perfume: Perfume) -> [String] {
        let rankedSeasons = perfume.seasonRanking
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(2)
            .map(\.name)
        let seasons = rankedSeasons.isEmpty ? (perfume.season ?? []) : Array(rankedSeasons)
        return PerfumePresentationSupport.displaySeasons(seasons)
    }

    private func updateSelectedTab(_ tab: ContentTab) {
        perfumeInfoContentStack.isHidden = tab != .perfumeInfo
        directInputContentStack.isHidden = tab != .directInput
        updateChipButton(perfumeInfoChipButton, title: "향수 정보", isSelected: tab == .perfumeInfo)
        updateChipButton(directInputChipButton, title: "직접 입력할 정보", isSelected: tab == .directInput)
    }

    private func updateChipButton(_ button: UIButton, title: String, isSelected: Bool) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseForegroundColor = isSelected ? .white : .label
        configuration.baseBackgroundColor = isSelected ? UIColor(hex: "#1F1F1F") : UIColor(hex: "#F3F3F5")
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        button.configuration = configuration
    }

    @objc private func perfumeInfoTabTapped() {
        updateSelectedTab(.perfumeInfo)
    }

    @objc private func directInputTabTapped() {
        updateSelectedTab(.directInput)
    }

    @objc private func retryTapped() {
        navigationController?.popViewController(animated: true)
        onRetrySearch?()
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func registerTapped() {
        let status = CollectedPerfumeUsageStatus.allCases[statusControl.selectedSegmentIndex]
        let frequency = CollectedPerfumeUsageFrequency.allCases[frequencyControl.selectedSegmentIndex]
        let preference = CollectedPerfumePreferenceLevel.allCases[preferenceControl.selectedSegmentIndex]
        let info = CollectedPerfumeRegistrationInfo(
            usageStatus: status,
            usageFrequency: frequency,
            preferenceLevel: preference,
            memo: memoTextView.text
        )
        onRegister?(info)
    }
}

private final class RegistrationChipWrapView: UIView {
    private let values: [String]
    private var chipViews: [UILabel] = []

    init(values: [String]) {
        self.values = values
        super.init(frame: .zero)
        setupChips()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupChips() {
        chipViews = values.map { value in
            let label = UILabel()
            label.text = value
            label.font = .systemFont(ofSize: 14, weight: .semibold)
            label.textColor = .label
            label.backgroundColor = UIColor(hex: "#F3F3F5")
            label.layer.cornerRadius = 16
            label.layer.masksToBounds = true
            label.textAlignment = .center
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            addSubview(label)
            return label
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let horizontalSpacing: CGFloat = 8
        let verticalSpacing: CGFloat = 8
        let horizontalPadding: CGFloat = 16
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        chipViews.forEach { label in
            let textWidth = label.sizeThatFits(
                CGSize(width: bounds.width, height: 34)
            ).width
            let chipWidth = min(max(textWidth + horizontalPadding * 2, 48), bounds.width)
            if x > 0, x + chipWidth > bounds.width {
                x = 0
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            label.frame = CGRect(x: x, y: y, width: chipWidth, height: 34)
            x += chipWidth + horizontalSpacing
            rowHeight = max(rowHeight, 34)
        }
    }

    override var intrinsicContentSize: CGSize {
        let availableWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 40
        let horizontalSpacing: CGFloat = 8
        let verticalSpacing: CGFloat = 8
        let horizontalPadding: CGFloat = 16
        var x: CGFloat = 0
        var y: CGFloat = 0
        let rowHeight: CGFloat = 34

        chipViews.forEach { label in
            let textWidth = label.sizeThatFits(
                CGSize(width: availableWidth, height: 34)
            ).width
            let chipWidth = min(max(textWidth + horizontalPadding * 2, 48), availableWidth)
            if x > 0, x + chipWidth > availableWidth {
                x = 0
                y += rowHeight + verticalSpacing
            }
            x += chipWidth + horizontalSpacing
        }

        return CGSize(width: UIView.noIntrinsicMetric, height: y + rowHeight)
    }
}
