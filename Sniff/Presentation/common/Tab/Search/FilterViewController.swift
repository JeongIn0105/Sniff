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
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 28
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
        $0.setTitle("58개 향수 보기", for: .normal)
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
            $0.top.equalTo(handleView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
        }

        activeFilterScrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(36)
        }

        activeFilterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
            $0.height.equalToSuperview()
        }

        bottomView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(100)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(activeFilterScrollView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top)
        }

            // 스크롤 내용
        scrollView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-16)
            $0.width.equalTo(scrollView)
        }

            // 필터 섹션 추가
        contentStackView.addArrangedSubview(makeSectionView(
            title: "무드&이미지",
            tags: MoodTag.allCases.map { $0.displayName },
            type: .mood
        ))

        contentStackView.addArrangedSubview(makeDivider())

        contentStackView.addArrangedSubview(makeSectionView(
            title: "농도",
            tags: Concentration.allCases.map { $0.displayName },
            type: .concentration
        ))

        contentStackView.addArrangedSubview(makeDivider())

        contentStackView.addArrangedSubview(makeSectionView(
            title: "계절",
            tags: Season.allCases.map { $0.displayName },
            type: .season
        ))

            // 하단 버튼
        [resetButton, applyButton].forEach { bottomView.addSubview($0) }

        resetButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(16)
            $0.width.equalTo(100)
            $0.height.equalTo(52)
        }

        applyButton.snp.makeConstraints {
            $0.leading.equalTo(resetButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalTo(resetButton)
            $0.height.equalTo(52)
        }
    }

        // MARK: - Bind ViewModel

    private func bindViewModel() {
        let input = FilterViewModel.Input(
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
                self?.applyButton.setTitle("\(count)개 향수 보기", for: .normal)
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
                self?.updateActiveFilterBar(filter: filter)
                self?.updateTagButtons(filter: filter)
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
        MoodTag.allCases.forEach { tag in
            tagButtons[tag.rawValue]?.isSelected = filter.moodTags.contains(tag)
        }
        Concentration.allCases.forEach { conc in
            tagButtons[conc.rawValue]?.isSelected = filter.concentrations.contains(conc)
        }
        Season.allCases.forEach { season in
            tagButtons[season.rawValue]?.isSelected = filter.seasons.contains(season)
        }
    }

        // MARK: - 상단 활성 필터 바

    private func updateActiveFilterBar(filter: SearchFilter) {
        activeFilterStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let allSelected: [String] = filter.moodTags.map { $0.displayName }
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
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

            // 탭 시 해당 필터 해제
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.removeFilter(named: title)
            })
            .disposed(by: disposeBag)

        return button
    }

    private func removeFilter(named title: String) {
        if let tag = MoodTag(rawValue: title) {
            moodTagToggleRelay.accept(tag)
        } else if let conc = Concentration(rawValue: title) {
            concentrationToggleRelay.accept(conc)
        } else if let season = Season(rawValue: title) {
            seasonToggleRelay.accept(season)
        }
    }

        // MARK: - Section 생성

    private enum TagType { case mood, concentration, season }

    private func makeSectionView(title: String, tags: [String], type: TagType) -> UIView {
        let container = UIView()

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = .systemFont(ofSize: 16, weight: .semibold)
        }

        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
        }

        let wrapView = TagWrapView(tags: tags) { [weak self] selectedTag in
            guard let self else { return }
            switch type {
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
            if let title = btn.title(for: .normal) {
                tagButtons[title] = btn
            }
        }

        container.addSubview(wrapView)
        wrapView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalToSuperview()
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
}

    // MARK: - TagWrapView
    // 태그 pill들을 자동 줄바꿈으로 배치하는 커스텀 뷰

final class TagWrapView: UIView {

    private let tags: [String]
    private let onSelect: (String) -> Void
    private(set) var buttons: [UIButton] = []
    private let spacing: CGFloat = 8
    private let lineSpacing: CGFloat = 10

    init(tags: [String], onSelect: @escaping (String) -> Void) {
        self.tags = tags
        self.onSelect = onSelect
        super.init(frame: .zero)
        setupButtons()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupButtons() {
        tags.forEach { tag in
            let button = UIButton(type: .system)
            button.setTitle(tag, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.setTitleColor(.label, for: .normal)
            button.setTitleColor(.white, for: .selected)
            button.backgroundColor = .systemBackground
            button.layer.cornerRadius = 18
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray3.cgColor
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
            button.addTarget(self, action: #selector(tagTapped(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }
    }

    @objc private func tagTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        sender.backgroundColor = sender.isSelected ? .label : .systemBackground
        sender.layer.borderColor = sender.isSelected
        ? UIColor.label.cgColor
        : UIColor.systemGray3.cgColor
        if let title = sender.title(for: .normal) {
            onSelect(title)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var x: CGFloat = 0
        var y: CGFloat = 0

        buttons.forEach { button in
            button.sizeToFit()
            let w = button.frame.width + 28
            let h: CGFloat = 36

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
