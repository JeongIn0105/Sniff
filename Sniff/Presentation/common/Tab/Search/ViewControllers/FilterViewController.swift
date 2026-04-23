//
//  FilterViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//
    // FilterViewController.swift
    // 킁킁(Sniff) - 필터 바텀시트 ViewController

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class FilterViewController: UIViewController {

        // MARK: - Properties
    private let viewModel: FilterViewModel
    private let disposeBag = DisposeBag()
    private var currentFilter = SearchFilter()

    private let scentFamilyToggleRelay = PublishRelay<ScentFamilyFilter>()
    private let moodTagToggleRelay = PublishRelay<MoodTag>()
    private let concentrationToggleRelay = PublishRelay<Concentration>()
    private let seasonToggleRelay = PublishRelay<Season>()
    private let resetRelay = PublishRelay<Void>()
    private let applyRelay = PublishRelay<Void>()

    var onApply: ((SearchFilter) -> Void)?

        // MARK: - UI Components

    private let handleView = UIView().then {
        $0.backgroundColor = .systemGray4
        $0.layer.cornerRadius = 2.5
    }

    private let titleLabel = UILabel().then {
        $0.text = "필터"
        $0.font = .systemFont(ofSize: 18, weight: .semibold)
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
    }

        // 선택된 필터 상단 바
    private let activeFilterScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.isHidden = true
    }

    private let activeFilterStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
    }

        // 하단 버튼 영역
    private let bottomView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let resetButton = UIButton(type: .system).then {
        $0.setTitle("초기화", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        $0.setTitleColor(.label, for: .normal)
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 12
    }

    private let applyButton = UIButton(type: .system).then {
        $0.setTitle("향수 58개 보기", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.setTitleColor(.white, for: .normal)
        $0.setTitleColor(.systemGray3, for: .disabled)
        $0.backgroundColor = .label
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
        setupUI()
        bindViewModel()
    }

        // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        [handleView, titleLabel, activeFilterScrollView, scrollView, bottomView].forEach {
            view.addSubview($0)
        }

        activeFilterScrollView.addSubview(activeFilterStackView)

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(20)
        }

        activeFilterScrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(32)
        }

        activeFilterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            $0.height.equalToSuperview()
        }

        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(92)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(activeFilterScrollView.snp.bottom).offset(4)
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
        [resetButton, applyButton].forEach { bottomView.addSubview($0) }

        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(12)
            $0.width.equalTo(100)
            $0.height.equalTo(48)
        }

        applyButton.snp.makeConstraints {
            $0.leading.equalTo(resetButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalTo(resetButton)
            $0.height.equalTo(48)
        }
    }

        // MARK: - Bind ViewModel

    private func bindViewModel() {
        let input = FilterViewModel.Input(
            scentFamilyToggle: scentFamilyToggleRelay.asObservable(),
            moodTagToggle: moodTagToggleRelay.asObservable(),
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
                self?.applyButton.setTitle("향수 \(count)개 보기", for: .normal)
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
                self?.applyButton.backgroundColor = enabled ? .label : .systemGray4
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
                self?.onApply?(filter)
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)

            // 버튼 바인딩
        resetButton.rx.tap
            .bind(to: resetRelay)
            .disposed(by: disposeBag)

        applyButton.rx.tap
            .bind(to: applyRelay)
            .disposed(by: disposeBag)
    }

        // MARK: - Tag Button 상태 업데이트

    private var tagButtons: [String: UIButton] = [:]

    private func updateTagButtons(filter: SearchFilter) {
        ScentFamilyFilter.allCases.forEach { family in
            tagButtons[family.displayName]?.isSelected = filter.scentFamilies.contains(family)
        }
        MoodTag.allCases.forEach { tag in
            tagButtons[tag.displayName]?.isSelected = filter.moodTags.contains(tag)
        }
        Concentration.allCases.forEach { conc in
            tagButtons[conc.displayName]?.isSelected = filter.concentrations.contains(conc)
        }
        Season.allCases.forEach { season in
            tagButtons[season.displayName]?.isSelected = filter.seasons.contains(season)
        }
    }

    private func updateTagAvailability(filter: SearchFilter) {
        let currentCount = SearchFilterEngine.filterPerfumes(viewModel.currentPerfumes, filter: filter).count

        ScentFamilyFilter.allCases.forEach { family in
            let isSelected = filter.scentFamilies.contains(family)
            tagButtons[family.displayName]?.isEnabled = isSelected || isScentFamilyAvailable(family, filter: filter, currentCount: currentCount)
        }

        MoodTag.allCases.forEach { tag in
            let isSelected = filter.moodTags.contains(tag)
            let isAtSelectionLimit = !isSelected && filter.moodTags.count >= 3
            tagButtons[tag.displayName]?.isEnabled = isSelected || (!isAtSelectionLimit && isMoodTagAvailable(tag, filter: filter, currentCount: currentCount))
        }

        Season.allCases.forEach { season in
            let isSelected = filter.seasons.contains(season)
            tagButtons[season.displayName]?.isEnabled = isSelected || isSeasonAvailable(season, filter: filter, currentCount: currentCount)
        }
    }

    private func isScentFamilyAvailable(_ family: ScentFamilyFilter, filter: SearchFilter, currentCount: Int) -> Bool {
        var candidateFilter = filter
        candidateFilter.scentFamilies.insert(family)
        let candidateCount = SearchFilterEngine.filterPerfumes(viewModel.currentPerfumes, filter: candidateFilter).count
        return candidateCount > 0 && candidateCount < currentCount
    }

    private func isMoodTagAvailable(_ tag: MoodTag, filter: SearchFilter, currentCount: Int) -> Bool {
        var candidateFilter = filter
        candidateFilter.moodTags.insert(tag)
        let candidateCount = SearchFilterEngine.filterPerfumes(viewModel.currentPerfumes, filter: candidateFilter).count
        return candidateCount > 0 && candidateCount < currentCount
    }

    private func isSeasonAvailable(_ season: Season, filter: SearchFilter, currentCount: Int) -> Bool {
        var candidateFilter = filter
        candidateFilter.seasons.insert(season)
        let candidateCount = SearchFilterEngine.filterPerfumes(viewModel.currentPerfumes, filter: candidateFilter).count
        return candidateCount > 0 && candidateCount < currentCount
    }

        // MARK: - 상단 활성 필터 바

    private func updateActiveFilterBar(filter: SearchFilter) {
        activeFilterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let allSelected: [String] = filter.scentFamilies.map { $0.displayName }
        + filter.moodTags.map { $0.displayName }
        + filter.concentrations.map { $0.displayName }
        + filter.seasons.map { $0.displayName }

        activeFilterScrollView.isHidden = allSelected.isEmpty

        allSelected.forEach { name in
            let chip = makeActiveChip(title: name)
            activeFilterStackView.addArrangedSubview(chip)
        }
    }

    private func makeActiveChip(title: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle("\(title)  ✕", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .label
        button.layer.cornerRadius = 16
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        button.configuration = configuration

            // 탭 시 해당 필터 해제
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.removeFilter(named: title)
            })
            .disposed(by: disposeBag)

        return button
    }

    private func removeFilter(named title: String) {
        if let family = ScentFamilyFilter(rawValue: title) {
            scentFamilyToggleRelay.accept(family)
        } else if let tag = MoodTag(rawValue: title) {
            moodTagToggleRelay.accept(tag)
        } else if let conc = Concentration(rawValue: title) {
            concentrationToggleRelay.accept(conc)
        } else if let season = Season(rawValue: title) {
            seasonToggleRelay.accept(season)
        }
    }

        // MARK: - Section 생성

    private enum TagType { case scentFamily, mood, concentration, season }

    private struct SectionSpec {
        let title: String
        let subtitle: String?
        let tags: [String]
        let type: TagType
        let topInset: CGFloat
        let bottomInset: CGFloat
    }

    private func addFilterSections() {
        let sections: [SectionSpec] = [
            .init(
                title: "향 계열",
                subtitle: nil,
                tags: ScentFamilyFilter.allCases.map(\.displayName),
                type: .scentFamily,
                topInset: 0,
                bottomInset: 25
            ),
            .init(
                title: "분위기 / 이미지",
                subtitle: nil,
                tags: MoodTag.imageTags.map(\.displayName) + MoodTag.vibeTags.map(\.displayName),
                type: .mood,
                topInset: 15,
                bottomInset: 25
            ),
            .init(
                title: "계절",
                subtitle: nil,
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
            $0.font = .systemFont(ofSize: 16, weight: .semibold)
        }

        let subtitleLabel = UILabel().then {
            $0.text = subtitle
            $0.font = .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = .secondaryLabel
            $0.numberOfLines = 0
            $0.isHidden = subtitle == nil
        }

        let headerView = UIView()
        [titleLabel, subtitleLabel].forEach { headerView.addSubview($0) }
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        if type == .scentFamily || type == .concentration {
            let infoButton = UIButton(type: .system).then {
                $0.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
                $0.tintColor = .systemGray2
            }
            headerView.addSubview(infoButton)
            infoButton.snp.makeConstraints {
                $0.leading.equalTo(titleLabel.snp.trailing).offset(4)
                $0.centerY.equalTo(titleLabel)
                $0.size.equalTo(16)
                $0.trailing.lessThanOrEqualToSuperview()
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
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        let wrapView = TagWrapView(tags: tags) { [weak self] selectedTag in
            guard let self else { return }
            switch type {
                case .scentFamily:
                    if let family = ScentFamilyFilter(rawValue: selectedTag) {
                        self.scentFamilyToggleRelay.accept(family)
                    }
                case .mood:
                    if let tag = MoodTag(rawValue: selectedTag) {
                        self.moodTagToggleRelay.accept(tag)
                    }
                case .concentration:
                    if let conc = Concentration(rawValue: selectedTag) {
                        self.concentrationToggleRelay.accept(conc)
                    }
                case .season:
                    if let season = Season(rawValue: selectedTag) {
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
            $0.top.equalTo(headerView.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalToSuperview().offset(-bottomInset)
        }

        return container
    }

    private func makeDivider() -> UIView {
        let view = UIView().then {
            $0.backgroundColor = .systemGray5
            $0.snp.makeConstraints { $0.height.equalTo(1) }
        }
        return view
    }

    private func presentConcentrationInfoSheet() {
        let infoViewController = ConcentrationInfoViewController()
        infoViewController.modalPresentationStyle = .pageSheet

        if let sheet = infoViewController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        present(infoViewController, animated: true)
    }

    private func presentScentFamilyInfoSheet() {
        let infoViewController = ScentFamilyInfoViewController()
        infoViewController.modalPresentationStyle = .pageSheet

        if let sheet = infoViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(infoViewController, animated: true)
    }
}

    // MARK: - TagWrapView
    // 태그 pill들을 자동 줄바꿈으로 배치하는 커스텀 뷰

final class TagWrapView: UIView {

    private let tags: [String]
    private let onSelect: (String) -> Void
    private(set) var buttons: [UIButton] = []
    private let spacing: CGFloat = 8
    private let lineSpacing: CGFloat = 8

    init(tags: [String], onSelect: @escaping (String) -> Void) {
        self.tags = tags
        self.onSelect = onSelect
        super.init(frame: .zero)
        setupButtons()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupButtons() {
        tags.forEach { tag in
            let button = FilterTagButton(type: .system)
            button.baseTitle = tag
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.backgroundColor = .systemBackground
            button.layer.cornerRadius = 18
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray3.cgColor
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            button.configuration = configuration
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

        var x: CGFloat = 0
        var y: CGFloat = 0

        buttons.forEach { button in
            button.sizeToFit()
            let w = button.frame.width + 20
            let h: CGFloat = 38

            if x + w > bounds.width && x > 0 {
                x = 0
                y += h + lineSpacing
            }

            button.frame = CGRect(x: x, y: y, width: w, height: h)
            x += w + spacing
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutSubviews()
        let maxY = buttons.map { $0.frame.maxY }.max() ?? 0
        return CGSize(width: UIView.noIntrinsicMetric, height: maxY)
    }
}

private final class FilterTagButton: UIButton {
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
        let title = isSelected ? "✓ \(baseTitle)" : baseTitle
        setTitle(title, for: .normal)
        let textColor: UIColor = isEnabled ? .label : .systemGray3
        setTitleColor(textColor, for: .normal)
        setTitleColor(textColor, for: .selected)
        setTitleColor(textColor, for: .highlighted)
        tintColor = textColor
        backgroundColor = isEnabled ? .systemBackground : UIColor.systemGray6
        layer.borderColor = isSelected
            ? UIColor.label.cgColor
            : (isEnabled ? UIColor.systemGray3.cgColor : UIColor.systemGray5.cgColor)
    }
}

private final class ConcentrationInfoViewController: UIViewController {
    private struct ConcentrationDescription {
        let title: String
        let description: String
    }

    private let items: [ConcentrationDescription] = [
        .init(title: "퍼퓸", description: "오일 함량이 가장 높아 향이 진하고 오래 유지되는 편이에요."),
        .init(title: "오드퍼퓸(EDP)", description: "일상에서 가장 무난하게 쓰기 좋고 지속력도 비교적 안정적이에요."),
        .init(title: "오드뚜왈렛(EDT)", description: "EDP보다 가볍고 산뜻해서 데일리로 부담 없이 쓰기 좋아요."),
        .init(title: "오드콜로뉴(EDC)", description: "향이 가장 가볍고 지속 시간이 짧아 리프레시용에 가까워요."),
        .init(title: "오프레시", description: "아주 옅고 가벼운 타입으로 짧게 향을 더하는 느낌에 가까워요.")
    ]

    private let titleLabel = UILabel().then {
        $0.text = "농도 설명"
        $0.font = .systemFont(ofSize: 18, weight: .semibold)
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 16
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(stackView)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        stackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-20)
        }

        items.forEach { item in
            stackView.addArrangedSubview(ConcentrationInfoRowView(title: item.title, description: item.description))
        }
    }
}

private final class ConcentrationInfoRowView: UIView {
    init(title: String, description: String) {
        super.init(frame: .zero)

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = .systemFont(ofSize: 15, weight: .semibold)
            $0.textColor = .label
        }

        let descriptionLabel = UILabel().then {
            $0.text = description
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .secondaryLabel
            $0.numberOfLines = 0
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 4
        }

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

private final class ScentFamilyInfoViewController: UIViewController {
    private let titleLabel = UILabel().then {
        $0.text = "향 계열 설명"
        $0.font = .systemFont(ofSize: 18, weight: .semibold)
    }

    private let descriptionLabel = UILabel().then {
        $0.text = "필터의 향 계열 칩이 어떤 느낌인지 한눈에 볼 수 있어요."
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 14
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        [titleLabel, descriptionLabel, scrollView].forEach { view.addSubview($0) }
        scrollView.addSubview(stackView)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20))
            $0.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }

        ScentFamilyFilter.allCases.forEach { family in
            stackView.addArrangedSubview(
                ConcentrationInfoRowView(title: family.displayName, description: family.descriptionText)
            )
        }
    }
}
