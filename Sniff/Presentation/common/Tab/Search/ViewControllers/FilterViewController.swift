//
//  FilterViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class FilterViewController: UIViewController {

    fileprivate enum Layout {
        static let sectionHorizontalInset: CGFloat = 24
        static let sectionHeaderToTagsSpacing: CGFloat = 10
        static let sectionDividerSpacing: CGFloat = 18
        static let chipSpacing: CGFloat = 8
        static let chipLineSpacing: CGFloat = 10
        static let chipSelectedBackground = UIColor(red: 0.96, green: 0.93, blue: 0.90, alpha: 1)
        static let chipSelectedBorder = UIColor(red: 0.86, green: 0.83, blue: 0.80, alpha: 1)
        static let chipBorder = UIColor(red: 0.87, green: 0.87, blue: 0.87, alpha: 1)
        static let chipHeight: CGFloat = 40
        static let chipRadius: CGFloat = 20
        static let chipHorizontalPadding: CGFloat = 18
        static let resetButtonBackground = UIColor(hex: "#F6F6F8")
        static let resetButtonTitle = UIColor(hex: "#8E8E93")
        static let applyButtonBackground = UIColor(hex: "#1F1F1F")
        static let applyButtonDisabledBackground = UIColor(hex: "#D9D9D9")
        static let applyButtonTitle = UIColor.white
    }

    private enum SelectionLimit {
        static let scentFamilies = 3
    }

    // MARK: - Properties

    private let viewModel: FilterViewModel
    private let disposeBag = DisposeBag()
    private var currentFilter = SearchFilter()
    private var tagButtons: [String: UIButton] = [:]
    private var shouldApplyResetOnDismiss = false
    private var didApplyExplicitly = false

    private let scentFamilyToggleRelay = PublishRelay<ScentFamilyFilter>()
    private let concentrationToggleRelay = PublishRelay<Concentration>()
    private let seasonToggleRelay = PublishRelay<Season>()
    private let resetRelay = PublishRelay<Void>()
    private let applyRelay = PublishRelay<Void>()

    var onApply: ((SearchFilter) -> Void)?

    private enum TagType {
        case scentFamily
        case concentration
        case season
    }

    private struct SectionSpec {
        let title: String
        let subtitle: String?
        let tags: [String]
        let type: TagType
        let topInset: CGFloat
        let bottomInset: CGFloat
    }

    // MARK: - UI Components

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
    }

    private let titleLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Filter.title
        $0.font = .systemFont(ofSize: 17, weight: .semibold)
        $0.textColor = .label
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
    }

    private let titleDividerView = UIView().then {
        $0.backgroundColor = .systemGray5
    }

        // 하단 버튼 영역
    private let bottomView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let bottomDividerView = UIView().then {
        $0.backgroundColor = .systemGray5
    }

    private let resetButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Filter.reset, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.setTitleColor(Layout.resetButtonTitle, for: .normal)
        $0.setTitleColor(Layout.resetButtonTitle.withAlphaComponent(0.5), for: .highlighted)
        $0.backgroundColor = Layout.resetButtonBackground
        $0.layer.cornerRadius = 12
    }

    private let applyButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Filter.apply, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.setTitleColor(Layout.applyButtonTitle, for: .normal)
        $0.setTitleColor(Layout.applyButtonTitle, for: .disabled)
        $0.backgroundColor = Layout.applyButtonBackground
        $0.layer.cornerRadius = 12
    }

    // MARK: - Init

    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentationController?.delegate = self
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

        [backButton, titleLabel, titleDividerView, scrollView, bottomView].forEach {
            view.addSubview($0)
        }

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(18)
            $0.leading.equalToSuperview().offset(20)
            $0.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.leading.equalTo(backButton.snp.trailing).offset(8)
        }

        titleDividerView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(98)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleDividerView.snp.bottom).offset(22)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top)
        }

            // 스크롤 내용
        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints {
            $0.top.equalTo(scrollView.contentLayoutGuide.snp.top).offset(4)
            $0.leading.equalTo(scrollView.contentLayoutGuide.snp.leading)
            $0.trailing.equalTo(scrollView.contentLayoutGuide.snp.trailing)
            $0.bottom.equalTo(scrollView.contentLayoutGuide.snp.bottom).offset(-12)
            $0.width.equalTo(scrollView.frameLayoutGuide.snp.width)
        }

        addFilterSections()

            // 하단 버튼
        [bottomDividerView, resetButton, applyButton].forEach { bottomView.addSubview($0) }

        bottomDividerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.sectionHorizontalInset)
            $0.top.equalToSuperview().offset(12)
            $0.width.equalTo(88)
            $0.height.equalTo(48)
        }

        applyButton.snp.makeConstraints {
            $0.leading.equalTo(resetButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-Layout.sectionHorizontalInset)
            $0.top.equalTo(resetButton)
            $0.height.equalTo(48)
        }

        backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.applyPendingResetIfNeeded()
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Bind ViewModel

    private func bindViewModel() {
        // 각 필터 탭 이벤트를 ViewModel 입력으로 묶어 바텀시트 상태를 한 곳에서 관리한다.
        let input = FilterViewModel.Input(
            scentFamilyToggle: scentFamilyToggleRelay.asObservable(),
            moodTagToggle: .empty(),
            concentrationToggle: concentrationToggleRelay.asObservable(),
            seasonToggle: seasonToggleRelay.asObservable(),
            resetTrigger: resetRelay.asObservable(),
            applyTrigger: applyRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

            // 결과 수 → 버튼 타이틀
        output.resultCount
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.applyButton.setTitle(AppStrings.UIKitScreens.Filter.applyCount(count), for: .normal)
            })
            .disposed(by: disposeBag)

            // 적용 가능 여부
        output.isApplyEnabled
            .observe(on: MainScheduler.instance)
            .bind(to: applyButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.isApplyEnabled
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] enabled in
                self?.applyButton.backgroundColor = enabled
                    ? Layout.applyButtonBackground
                    : Layout.applyButtonDisabledBackground
            })
            .disposed(by: disposeBag)

            // 필터 변경 → 상단 활성 필터 바 업데이트
        output.currentFilter
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                self?.currentFilter = filter
                self?.updateActiveFilterBar(filter: filter)
                self?.updateTagButtons(filter: filter)
                self?.updateTagAvailability(filter: filter)
            })
            .disposed(by: disposeBag)

            // 적용
        output.onApply
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                guard let self else { return }
                self.didApplyExplicitly = true
                self.shouldApplyResetOnDismiss = false
                self.onApply?(filter)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)

            // 버튼 바인딩
        resetButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.currentFilter = SearchFilter()
                self.shouldApplyResetOnDismiss = true
                self.resetRelay.accept(())
            })
            .disposed(by: disposeBag)

        applyButton.rx.tap
            .bind(to: applyRelay)
            .disposed(by: disposeBag)
    }

    private func applyPendingResetIfNeeded() {
        guard shouldApplyResetOnDismiss, !didApplyExplicitly else { return }
        shouldApplyResetOnDismiss = false
        onApply?(currentFilter)
    }

    // MARK: - Tag Button State

    private func updateTagButtons(filter: SearchFilter) {
        // 현재 필터 상태와 각 칩의 선택 상태를 동기화한다.
        ScentFamilyFilter.allCases.forEach { family in
            tagButtons[family.displayName]?.isSelected = filter.scentFamilies.contains(family)
        }
        Concentration.allCases.forEach { conc in
            tagButtons[conc.displayName]?.isSelected = filter.concentrations.contains(conc)
        }
        Season.allCases.forEach { season in
            tagButtons[season.displayName]?.isSelected = filter.seasons.contains(season)
        }
    }

    private func updateTagAvailability(filter: SearchFilter) {
        ScentFamilyFilter.allCases.forEach { family in
            let isSelected = filter.scentFamilies.contains(family)
            let isAtSelectionLimit = !isSelected && filter.scentFamilies.count >= SelectionLimit.scentFamilies
            guard let button = tagButtons[family.displayName] as? FilterTagButton else { return }
            button.isEnabled = !isAtSelectionLimit
            button.isDimmed = isAtSelectionLimit
        }

        let hasSelectedConcentration = !filter.concentrations.isEmpty
        Concentration.allCases.forEach { concentration in
            guard let button = tagButtons[concentration.displayName] as? FilterTagButton else { return }
            button.isEnabled = true
            button.isDimmed = hasSelectedConcentration && !filter.concentrations.contains(concentration)
        }

        let hasSelectedSeason = !filter.seasons.isEmpty
        Season.allCases.forEach { season in
            guard let button = tagButtons[season.displayName] as? FilterTagButton else { return }
            button.isEnabled = true
            button.isDimmed = hasSelectedSeason && !filter.seasons.contains(season)
        }
    }

        // MARK: - 상단 활성 필터 바

    private func updateActiveFilterBar(filter _: SearchFilter) {
        // 선택 상태는 각 태그 버튼 자체로만 표시한다. 상단 X 칩은 노출하지 않는다.
    }

    // MARK: - Section Layout

    private func addFilterSections() {
        // 섹션 간격은 topInset / bottomInset으로 관리해서 화면에서 직접 조정하기 쉽게 둔다.
        let sections: [SectionSpec] = [
            .init(
                title: AppStrings.UIKitScreens.Filter.scentFamily,
                subtitle: "최대 3개 선택 가능",
                tags: ScentFamilyFilter.allCases.map(\.displayName),
                type: .scentFamily,
                topInset: 0,
                bottomInset: 25
            ),
            .init(
                title: AppStrings.UIKitScreens.Filter.concentration,
                subtitle: "최대 1개 선택 가능",
                tags: Concentration.allCases.map(\.displayName),
                type: .concentration,
                topInset: 15,
                bottomInset: 25
            ),
            .init(
                title: AppStrings.UIKitScreens.Filter.season,
                subtitle: "최대 1개 선택 가능",
                tags: Season.allCases.map(\.displayName),
                type: .season,
                topInset: 15,
                bottomInset: 0
            )
        ]

        sections.enumerated().forEach { index, section in
            contentStackView.addArrangedSubview(makeSectionView(
                title: section.title,
                subtitle: section.subtitle,
                tags: section.tags,
                type: section.type,
                topInset: section.topInset,
                bottomInset: section.bottomInset
            ))

            if index < sections.count - 1 {
                contentStackView.addArrangedSubview(makeDivider())
            }
        }
    }

    private func makeSectionView(
        title: String,
        subtitle: String?,
        tags: [String],
        type: TagType,
        topInset: CGFloat,
        bottomInset: CGFloat
    ) -> UIView {
        let container = UIView()

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = .systemFont(ofSize: 18, weight: .bold)
            $0.textColor = .label
        }

        let subtitleLabel = UILabel().then {
            $0.text = subtitle
            $0.font = .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = .tertiaryLabel
            $0.numberOfLines = 0
            $0.isHidden = subtitle == nil
        }

        let headerView = UIView()
        [titleLabel, subtitleLabel].forEach { headerView.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(26)
            $0.centerY.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualToSuperview()
        }

        if type == .scentFamily || type == .concentration {
            let infoButton = UIButton(type: .system).then {
                $0.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
                $0.tintColor = .systemGray2
            }
            headerView.addSubview(infoButton)
            infoButton.snp.makeConstraints {
                $0.leading.equalTo(titleLabel.snp.trailing).offset(6)
                $0.centerY.equalTo(titleLabel)
                $0.size.equalTo(18)
            }
            infoButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self else { return }
                    if type == .scentFamily {
                        self.presentScentFamilyInfoSheet()
                    } else {
                        self.presentConcentrationInfoSheet()
                    }
                })
                .disposed(by: disposeBag)
        }

        container.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(topInset)
            $0.leading.equalToSuperview().offset(Layout.sectionHorizontalInset)
            $0.trailing.lessThanOrEqualToSuperview().offset(-Layout.sectionHorizontalInset)
        }

        let wrapView = TagWrapView(
            tags: tags,
            spacing: Layout.chipSpacing,
            lineSpacing: Layout.chipLineSpacing
        ) { [weak self] selectedTag in
            guard let self else { return }
            // 태그 문자열을 실제 필터 enum으로 다시 매핑해 토글 이벤트를 보낸다.
            switch type {
                case .scentFamily:
                    if let family = ScentFamilyFilter.fromDisplayName(selectedTag) {
                        self.scentFamilyToggleRelay.accept(family)
                    }
                case .concentration:
                    if let conc = Concentration.fromDisplayName(selectedTag) {
                        self.concentrationToggleRelay.accept(conc)
                    }
                case .season:
                    if let season = Season.fromDisplayName(selectedTag) {
                        self.seasonToggleRelay.accept(season)
                    }
            }
        }

            // 버튼 등록
        wrapView.buttons.forEach { btn in
            if let filterButton = btn as? FilterTagButton {
                tagButtons[filterButton.baseTitle] = filterButton
            }
        }

        container.addSubview(wrapView)
        wrapView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(Layout.sectionHeaderToTagsSpacing)
            $0.leading.equalToSuperview().offset(Layout.sectionHorizontalInset)
            $0.trailing.equalToSuperview().offset(-Layout.sectionHorizontalInset)
            $0.bottom.equalToSuperview().offset(-bottomInset)
        }

        return container
    }

    private func makeDivider() -> UIView {
        let view = UIView().then {
            $0.backgroundColor = .systemGray5
            $0.snp.makeConstraints { $0.height.equalTo(1) }
        }
        contentStackView.setCustomSpacing(Layout.sectionDividerSpacing, after: view)
        return view
    }

    private func presentConcentrationInfoSheet() {
        let infoViewController = ConcentrationInfoViewController()
        infoViewController.modalPresentationStyle = .pageSheet

        if let sheet = infoViewController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }

        present(infoViewController, animated: true)
    }

    private func presentScentFamilyInfoSheet() {
        let infoViewController = ScentFamilyInfoViewController()
        infoViewController.modalPresentationStyle = .pageSheet

        if let sheet = infoViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }

        present(infoViewController, animated: true)
    }
}

extension FilterViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        applyPendingResetIfNeeded()
    }
}

    // MARK: - TagWrapView
    // 태그 pill들을 자동 줄바꿈으로 배치하는 커스텀 뷰

final class TagWrapView: UIView {

    private let tags: [String]
    private let onSelect: (String) -> Void
    private(set) var buttons: [UIButton] = []
    private let spacing: CGFloat
    private let lineSpacing: CGFloat
    private var lastLaidOutWidth: CGFloat = 0

    init(
        tags: [String],
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        onSelect: @escaping (String) -> Void
    ) {
        self.tags = tags
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.onSelect = onSelect
        super.init(frame: .zero)
        setupButtons()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupButtons() {
        // 버튼 너비가 제각각이어서 스택뷰 대신 직접 줄바꿈 레이아웃을 만든다.
        tags.forEach { tag in
            let button = FilterTagButton(type: .system)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
            button.backgroundColor = .systemBackground
            button.layer.cornerRadius = FilterViewController.Layout.chipRadius
            button.layer.borderWidth = 1
            button.layer.borderColor = FilterViewController.Layout.chipBorder.cgColor
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: 10,
                leading: FilterViewController.Layout.chipHorizontalPadding,
                bottom: 10,
                trailing: FilterViewController.Layout.chipHorizontalPadding
            )
            configuration.background.cornerRadius = FilterViewController.Layout.chipRadius
            button.configuration = configuration
            button.baseTitle = tag
            button.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }
    }

    @objc private func tagTapped(_ sender: UIButton) {
        if let button = sender as? FilterTagButton {
            onSelect(button.baseTitle)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if lastLaidOutWidth != bounds.width {
            lastLaidOutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }

        // 현재 폭 안에서 넘치면 다음 줄로 보내는 단순 flow layout 방식이다.
        var x: CGFloat = 0
        var y: CGFloat = 0

        buttons.forEach { button in
            let fittingSize = button.sizeThatFits(
                CGSize(width: CGFloat.greatestFiniteMagnitude, height: FilterViewController.Layout.chipHeight)
            )
            let w = fittingSize.width
            let h = FilterViewController.Layout.chipHeight

            if x + w > bounds.width && x > 0 {
                x = 0
                y += h + lineSpacing
            }

            button.frame = CGRect(x: x, y: y, width: w, height: h)
            x += w + spacing
        }
    }

    override var intrinsicContentSize: CGSize {
        guard bounds.width > 0 else {
            return CGSize(width: UIView.noIntrinsicMetric, height: 0)
        }

        let maxY = buttons.map { $0.frame.maxY }.max() ?? 0
        return CGSize(width: UIView.noIntrinsicMetric, height: maxY)
    }
}

private final class FilterTagButton: UIButton {
    var isDimmed = false {
        didSet {
            updateAppearance()
        }
    }

    var baseTitle: String = "" {
        didSet {
            updateAppearance()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    private func updateAppearance() {
        setTitle(baseTitle, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 14, weight: isSelected ? .semibold : .regular)
        let textColor: UIColor
        if !isEnabled || isDimmed {
            textColor = .systemGray3
        } else {
            textColor = .label
        }
        setTitleColor(textColor, for: .normal)
        setTitleColor(textColor, for: .selected)
        setTitleColor(textColor, for: .highlighted)
        tintColor = textColor
        let backgroundColor = isSelected
            ? FilterViewController.Layout.chipSelectedBackground
            : UIColor.systemBackground.withAlphaComponent(isDimmed ? 0.45 : 1)
        var configuration = configuration ?? UIButton.Configuration.plain()
        configuration.baseForegroundColor = textColor
        configuration.background.backgroundColor = backgroundColor
        configuration.background.cornerRadius = FilterViewController.Layout.chipRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 10,
            leading: FilterViewController.Layout.chipHorizontalPadding,
            bottom: 10,
            trailing: FilterViewController.Layout.chipHorizontalPadding
        )
        self.configuration = configuration
        self.backgroundColor = backgroundColor
        layer.cornerRadius = FilterViewController.Layout.chipRadius
        layer.borderColor = isSelected
            ? FilterViewController.Layout.chipSelectedBorder.cgColor
            : FilterViewController.Layout.chipBorder.withAlphaComponent(isDimmed ? 0.45 : 1).cgColor
    }
}

private final class ConcentrationInfoViewController: UIViewController {
    private struct ConcentrationDescription {
        let title: String
        let description: String
        let fillRatio: CGFloat
    }

    private let items: [ConcentrationDescription] = [
        .init(
            title: "퍼퓸",
            description: "지속 시간 6시간 ~ 12시간",
            fillRatio: 0.88
        ),
        .init(
            title: "오 드 퍼퓸(EDP)",
            description: "지속 시간 4시간 ~ 6시간",
            fillRatio: 0.72
        ),
        .init(
            title: "오 드 뚜왈렛(EDT)",
            description: "지속 시간 2시간 ~ 4시간",
            fillRatio: 0.50
        ),
        .init(
            title: "오 드 콜로뉴(EDC)",
            description: "지속 시간 1시간 ~ 2시간",
            fillRatio: 0.28
        ),
        .init(
            title: "오 프레시",
            description: "지속 시간 30분 ~ 1시간",
            fillRatio: 0.12
        )
    ]

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Filter.concentrationInfoTitle
        $0.font = .systemFont(ofSize: 22, weight: .bold)
        $0.textColor = .label
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .label
    }

    private let descriptionLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Filter.concentrationInfoBody
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 26
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, closeButton, descriptionLabel, stackView].forEach {
            contentView.addSubview($0)
        }

        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-16)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(24)
            $0.size.equalTo(32)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(28)
            $0.bottom.equalToSuperview().inset(28)
        }

        items.forEach { item in
            stackView.addArrangedSubview(
                ConcentrationInfoRowView(
                    title: item.title,
                    description: item.description,
                    fillRatio: item.fillRatio
                )
            )
        }
    }
}

private final class ConcentrationInfoRowView: UIView {
    init(title: String, description: String, fillRatio: CGFloat) {
        super.init(frame: .zero)

        let iconContainerView = UIView().then {
            $0.backgroundColor = UIColor(hex: "#F5F5F5")
            $0.layer.cornerRadius = 10
            $0.layer.cornerCurve = .continuous
        }

        let bottleIconView = PerfumeBottleIconView()
        bottleIconView.configure(fillRatio: fillRatio)

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = .systemFont(ofSize: 15, weight: .semibold)
            $0.textColor = .label
            $0.numberOfLines = 1
        }

        let descriptionLabel = UILabel().then {
            $0.text = description
            $0.font = .systemFont(ofSize: 12, weight: .regular)
            $0.textColor = .secondaryLabel
            $0.numberOfLines = 0
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 7
        }

        addSubview(iconContainerView)
        iconContainerView.addSubview(bottleIconView)
        addSubview(stack)

        iconContainerView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.size.equalTo(40)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        bottleIconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 22, height: 26))
        }

        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(1)
            $0.leading.equalTo(iconContainerView.snp.trailing).offset(14)
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

private final class ScentFamilyInfoViewController: UIViewController {
    private let contentView = UIView()

    private let titleLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Filter.scentFamilyInfoTitle
        $0.font = .systemFont(ofSize: 22, weight: .bold)
        $0.textColor = .label
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .label
    }

    private let descriptionLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Filter.scentFamilyInfoBody
        $0.font = .systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 28
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, closeButton, descriptionLabel, stackView].forEach {
            contentView.addSubview($0)
        }

        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-16)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(24)
            $0.size.equalTo(32)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(34)
            $0.leading.trailing.equalToSuperview().inset(28)
            $0.bottom.equalToSuperview().inset(30)
        }

        ScentFamilyFilter.allCases.forEach { family in
            stackView.addArrangedSubview(
                ScentFamilyInfoRowView(family: family)
            )
        }
    }
}

private final class ScentFamilyInfoRowView: UIView {
    init(family: ScentFamilyFilter) {
        super.init(frame: .zero)

        let dotView = UIView().then {
            $0.backgroundColor = ScentFamilyColor.color(for: family.rawValue)
            $0.layer.cornerRadius = 5
        }

        let titleLabel = UILabel().then {
            $0.text = family.displayName
            $0.font = .systemFont(ofSize: 15, weight: .semibold)
            $0.textColor = .label
            $0.numberOfLines = 1
        }

        let descriptionLabel = UILabel().then {
            $0.text = family.descriptionText
            $0.font = .systemFont(ofSize: 13, weight: .regular)
            $0.textColor = .secondaryLabel
            $0.numberOfLines = 0
        }

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 7
        }

        [dotView, textStackView].forEach { addSubview($0) }

        dotView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview()
            $0.size.equalTo(10)
        }

        textStackView.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(dotView.snp.trailing).offset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

private final class PerfumeBottleIconView: UIView {
    private let capLayer = CAShapeLayer()
    private let neckLayer = CAShapeLayer()
    private let bodyLayer = CAShapeLayer()
    private let liquidLayer = CAShapeLayer()
    private var fillRatio: CGFloat = 0.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(fillRatio: CGFloat) {
        self.fillRatio = min(max(fillRatio, 0.08), 0.92)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let width = bounds.width
        let height = bounds.height
        let capRect = CGRect(x: width * 0.26, y: 0, width: width * 0.48, height: height * 0.28)
        let neckRect = CGRect(x: width * 0.34, y: height * 0.22, width: width * 0.32, height: height * 0.16)
        let bodyRect = CGRect(x: width * 0.18, y: height * 0.35, width: width * 0.64, height: height * 0.58)
        let liquidHeight = max(2, (bodyRect.height - 4) * fillRatio)
        let liquidRect = CGRect(
            x: bodyRect.minX + 2,
            y: bodyRect.maxY - 2 - liquidHeight,
            width: bodyRect.width - 4,
            height: liquidHeight
        )

        capLayer.path = UIBezierPath(ovalIn: capRect).cgPath
        neckLayer.path = UIBezierPath(rect: neckRect).cgPath
        bodyLayer.path = UIBezierPath(roundedRect: bodyRect, cornerRadius: 2.5).cgPath
        liquidLayer.path = UIBezierPath(rect: liquidRect).cgPath
    }

    private func setup() {
        [capLayer, neckLayer, bodyLayer, liquidLayer].forEach {
            layer.addSublayer($0)
        }

        capLayer.fillColor = UIColor.label.cgColor
        neckLayer.fillColor = UIColor.label.cgColor
        bodyLayer.fillColor = UIColor.clear.cgColor
        bodyLayer.strokeColor = UIColor.label.cgColor
        bodyLayer.lineWidth = 1.4
        liquidLayer.fillColor = UIColor.label.withAlphaComponent(0.18).cgColor
    }
}
