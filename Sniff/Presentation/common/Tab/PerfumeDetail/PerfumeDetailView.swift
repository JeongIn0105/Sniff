//
//  View.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import Kingfisher

final class PerfumeDetailViewController: UIViewController {

        // MARK: - Properties
    private let viewModel: PerfumeDetailViewModel
    private let disposeBag = DisposeBag()

    private let addToCollectionRelay = PublishRelay<Void>()
    private let addTastingRecordRelay = PublishRelay<Void>()

        // MARK: - Init
        // 검색 결과에서 넘어올 때 — 이미 데이터 있음
    init(viewModel: PerfumeDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - UI Components

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.contentInsetAdjustmentBehavior = .never
    }

    private let contentView = UIView()

        // 헤더 — 병 이미지 + 기본 정보
    private let headerView = UIView().then {
        $0.backgroundColor = UIColor.systemGray6
    }

    private let bottleImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private let brandLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 22, weight: .bold)
        $0.numberOfLines = 2
    }

    private let metaStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
    }

        // Accord 섹션
    private let accordSectionView = DetailSectionView(title: "향 계열")
    private let accordBarsView = AccordBarsView()

        // 노트 섹션
    private let notesSectionView = DetailSectionView(title: "향수 노트")
    private let notesView = NotesLayerView()

        // 향수 정보 섹션
    private let infoSectionView = DetailSectionView(title: "향수 정보")
    private let infoGridView = InfoGridView()

        // 하단 CTA
    private let bottomBarView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let addCollectionButton = UIButton(type: .system).then {
        $0.setTitle("컬렉션에 추가", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        $0.setTitleColor(.label, for: .normal)
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 12
    }

    private let addTastingButton = UIButton(type: .system).then {
        $0.setTitle("시향 기록 작성", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .label
        $0.layer.cornerRadius = 12
    }

        // 로딩
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

        // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
            // 뒤로가기 버튼 커스텀
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backButton.tintColor = .label
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        view.addSubview(bottomBarView)
        view.addSubview(loadingIndicator)

        scrollView.addSubview(contentView)

            // 컨텐츠 영역 뷰들
        [headerView, accordSectionView, accordBarsView,
         notesSectionView, notesView,
         infoSectionView, infoGridView].forEach {
            contentView.addSubview($0)
        }

            // 헤더 내부
        [bottleImageView, brandLabel, nameLabel, metaStackView].forEach {
            headerView.addSubview($0)
        }

            // 하단 바
        [addCollectionButton, addTastingButton].forEach {
            bottomBarView.addSubview($0)
        }

            // MARK: Constraints

        bottomBarView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(view.safeAreaInsets.bottom + 88)
        }

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomBarView.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

            // 헤더
        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
        }

        bottleImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(160)
            $0.height.equalTo(180)
        }

        brandLabel.snp.makeConstraints {
            $0.top.equalTo(bottleImageView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        metaStackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }

            // Accord 섹션
        accordSectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
        }

        accordBarsView.snp.makeConstraints {
            $0.top.equalTo(accordSectionView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

            // 노트 섹션
        notesSectionView.snp.makeConstraints {
            $0.top.equalTo(accordBarsView.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview()
        }

        notesView.snp.makeConstraints {
            $0.top.equalTo(notesSectionView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

            // 정보 섹션
        infoSectionView.snp.makeConstraints {
            $0.top.equalTo(notesView.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview()
        }

        infoGridView.snp.makeConstraints {
            $0.top.equalTo(infoSectionView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalToSuperview().offset(-32)
        }

            // 하단 버튼
        addCollectionButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(16)
            $0.width.equalTo(130)
            $0.height.equalTo(52)
        }

        addTastingButton.snp.makeConstraints {
            $0.leading.equalTo(addCollectionButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalTo(addCollectionButton)
            $0.height.equalTo(52)
        }
    }

        // MARK: - Bind

    private func bind() {
        let input = PerfumeDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            addToCollectionTap: addToCollectionRelay.asObservable(),
            addTastingRecordTap: addTastingRecordRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

            // 로딩
        output.isLoading
            .drive(onNext: { [weak self] loading in
                loading ? self?.loadingIndicator.startAnimating()
                : self?.loadingIndicator.stopAnimating()
                self?.scrollView.isHidden = loading
            })
            .disposed(by: disposeBag)

            // 향수 데이터
        output.perfume
            .compactMap { $0 }
            .drive(onNext: { [weak self] perfume in
                self?.configure(with: perfume)
            })
            .disposed(by: disposeBag)

            // 에러
        output.errorMessage
            .compactMap { $0 }
            .drive(onNext: { [weak self] message in
                self?.showErrorAlert(message: message)
            })
            .disposed(by: disposeBag)

            // 컬렉션 추가
        output.onAddToCollection
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfume in
                self?.navigateToAddCollection(perfume: perfume)
            })
            .disposed(by: disposeBag)

            // 시향 기록
        output.onAddTastingRecord
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfume in
                self?.navigateToTastingRecord(perfume: perfume)
            })
            .disposed(by: disposeBag)

            // 버튼
        addCollectionButton.rx.tap
            .bind(to: addToCollectionRelay)
            .disposed(by: disposeBag)

        addTastingButton.rx.tap
            .bind(to: addTastingRecordRelay)
            .disposed(by: disposeBag)
    }

        // MARK: - Configure

    private func configure(with perfume: Perfume) {
        bottleImageView.image = UIImage(systemName: "photo")

            // 이미지
        if let urlStr = perfume.imageUrl, let url = URL(string: urlStr) {
            bottleImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [.transition(.fade(0.2))]
            )
        }

            // 기본 정보
        brandLabel.text = perfume.brand
        nameLabel.text = perfume.name
        title = perfume.name

            // 메타 태그 (농도 + 성별)
        metaStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let conc = perfume.concentration {
            metaStackView.addArrangedSubview(MetaChipView(title: LocalizationMapper.concentration(conc)))
        }
        if let gender = perfume.gender {
            metaStackView.addArrangedSubview(MetaChipView(title: LocalizationMapper.gender(gender)))
        }

            // Accord 바
        let strengths = perfume.mainAccordStrengths.isEmpty
        ? Self.fallbackAccordStrengths(for: perfume.mainAccords)
        : perfume.mainAccordStrengths
        accordBarsView.configure(with: strengths)

            // 노트
        notesView.configure(
            top: perfume.topNotes ?? [],
            middle: perfume.middleNotes ?? [],
            base: perfume.baseNotes ?? []
        )

            // 향수 정보
        infoGridView.configure(with: perfume)
    }

        // MARK: - Navigation

    private func navigateToAddCollection(perfume: Perfume) {
        let alert = UIAlertController(
            title: "컬렉션 추가",
            message: "\(perfume.name)을(를) 컬렉션에 추가하는 화면은 곧 연결할게요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func navigateToTastingRecord(perfume: Perfume) {
        let alert = UIAlertController(
            title: "시향 기록 작성",
            message: "\(perfume.name)의 시향 기록 작성 화면은 곧 연결할게요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private static func fallbackAccordStrengths(for accords: [String]) -> [String: AccordStrength] {
        let fallbackStrengths: [AccordStrength] = [.dominant, .prominent, .moderate, .subtle]
        return Dictionary(
            uniqueKeysWithValues: accords.enumerated().map { index, accord in
                let strength = index < fallbackStrengths.count ? fallbackStrengths[index] : .subtle
                return (accord, strength)
            }
        )
    }
}

    // MARK: - DetailSectionView

final class DetailSectionView: UIView {

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
    }

    private let divider = UIView().then {
        $0.backgroundColor = .systemGray5
    }

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        [divider, titleLabel].forEach { addSubview($0) }

        divider.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
            $0.bottom.equalToSuperview()
        }
    }
}

    // MARK: - AccordBarsView
    // 향 계열 강도를 바 차트로 시각화

final class AccordBarsView: UIView {

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 10
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with strengths: [String: AccordStrength]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            // 강도 내림차순 정렬
        let sorted = strengths.sorted { $0.value.weight > $1.value.weight }

        sorted.forEach { (accord, strength) in
            let row = AccordBarRow(
                accord: accord,
                strength: strength
            )
            stackView.addArrangedSubview(row)
        }
    }
}

final class AccordBarRow: UIView {

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .label
    }

    private let barTrack = UIView().then {
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 4
    }

    private let barFill = UIView().then {
        $0.layer.cornerRadius = 4
    }

    private let strengthLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 11)
        $0.textColor = .secondaryLabel
    }

    init(accord: String, strength: AccordStrength) {
        super.init(frame: .zero)
        setupUI()
        configure(accord: accord, strength: strength)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        [nameLabel, barTrack, strengthLabel].forEach { addSubview($0) }
        barTrack.addSubview(barFill)

        nameLabel.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.width.equalTo(90)
        }

        barTrack.snp.makeConstraints {
            $0.leading.equalTo(nameLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(8)
            $0.trailing.equalTo(strengthLabel.snp.leading).offset(-8)
        }

        strengthLabel.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.width.equalTo(60)
        }

        snp.makeConstraints { $0.height.equalTo(28) }
    }

    private func configure(accord: String, strength: AccordStrength) {
        nameLabel.text = LocalizationMapper.accord(accord)
        barFill.backgroundColor = ScentFamilyColor.color(for: accord)

        let strengthText: String
        switch strength {
            case .dominant:  strengthText = "지배적"
            case .prominent: strengthText = "강함"
            case .moderate:  strengthText = "보통"
            case .subtle:    strengthText = "은은함"
        }
        strengthLabel.text = strengthText

            // 바 너비는 layoutSubviews에서 설정
        barFill.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(strength.weight)
        }
    }
}

    // MARK: - NotesLayerView
    // 탑/미들/베이스 노트 3레이어

final class NotesLayerView: UIView {

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

    func configure(top: [String], middle: [String], base: [String]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if !top.isEmpty {
            stackView.addArrangedSubview(NoteRowView(layer: "탑 노트", notes: top, opacity: 0.6))
        }
        if !middle.isEmpty {
            stackView.addArrangedSubview(NoteRowView(layer: "미들 노트", notes: middle, opacity: 0.8))
        }
        if !base.isEmpty {
            stackView.addArrangedSubview(NoteRowView(layer: "베이스 노트", notes: base, opacity: 1.0))
        }

        if top.isEmpty && middle.isEmpty && base.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "노트 정보가 없어요"
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.font = .systemFont(ofSize: 14)
            stackView.addArrangedSubview(emptyLabel)
        }
    }
}

final class NoteRowView: UIView {

    init(layer: String, notes: [String], opacity: CGFloat) {
        super.init(frame: .zero)
        setupUI(layer: layer, notes: notes, opacity: opacity)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(layer: String, notes: [String], opacity: CGFloat) {
        let layerLabel = UILabel().then {
            $0.text = layer
            $0.font = .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = .secondaryLabel
            $0.alpha = opacity
        }

        let notesWrap = NoteChipsView(notes: notes)

        addSubview(layerLabel)
        addSubview(notesWrap)

        layerLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.width.equalTo(72)
        }

        notesWrap.snp.makeConstraints {
            $0.leading.equalTo(layerLabel.snp.trailing).offset(8)
            $0.top.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}

final class NoteChipsView: UIView {

    private let notes: [String]

    init(notes: [String]) {
        self.notes = notes
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        subviews.forEach { $0.removeFromSuperview() }

        var x: CGFloat = 0
        var y: CGFloat = 0
        let spacing: CGFloat = 6
        let lineSpacing: CGFloat = 6
        let height: CGFloat = 26

        notes.forEach { note in
            let chip = makeChip(text: note)
            chip.sizeToFit()
            let w = chip.frame.width + 20

            if x + w > bounds.width && x > 0 {
                x = 0
                y += height + lineSpacing
            }

            chip.frame = CGRect(x: x, y: y, width: w, height: height)
            addSubview(chip)
            x += w + spacing
        }
    }

    override var intrinsicContentSize: CGSize {
        var x: CGFloat = 0
        var y: CGFloat = 0
        let spacing: CGFloat = 6
        let lineSpacing: CGFloat = 6
        let height: CGFloat = 26

        notes.forEach { note in
            let approxWidth = (note as NSString)
                .size(withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                .width + 20

            if x + approxWidth > (UIScreen.main.bounds.width - 120) && x > 0 {
                x = 0
                y += height + lineSpacing
            }
            x += approxWidth + spacing
        }

        return CGSize(width: UIView.noIntrinsicMetric, height: y + height)
    }

    private func makeChip(text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .label

        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 13
        container.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
        }
        return container
    }
}

    // MARK: - InfoGridView
    // 지속력 / 확산력 / 계절 / 상황 정보 그리드

final class InfoGridView: UIView {

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

    func configure(with perfume: Perfume) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if let longevity = perfume.longevity {
            stackView.addArrangedSubview(
                InfoRowView(icon: "clock", label: "지속력", value: LocalizationMapper.longevity(longevity))
            )
        }

        if let sillage = perfume.sillage {
            stackView.addArrangedSubview(
                InfoRowView(icon: "wind", label: "확산력", value: LocalizationMapper.sillage(sillage))
            )
        }

        if let seasons = perfume.season, !seasons.isEmpty {
            let seasonText = seasons.map { LocalizationMapper.season($0) }.joined(separator: " · ")
            stackView.addArrangedSubview(
                InfoRowView(icon: "leaf", label: "계절", value: seasonText)
            )
        }

        if let situations = perfume.situation, !situations.isEmpty {
            stackView.addArrangedSubview(
                InfoRowView(icon: "person.2", label: "상황", value: situations.joined(separator: " · "))
            )
        }
    }
}

final class InfoRowView: UIView {

    init(icon: String, label: String, value: String) {
        super.init(frame: .zero)
        setupUI(icon: icon, label: label, value: value)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(icon: String, label: String, value: String) {
        let iconView = UIImageView().then {
            $0.image = UIImage(systemName: icon)
            $0.tintColor = .secondaryLabel
            $0.contentMode = .scaleAspectFit
        }

        let labelView = UILabel().then {
            $0.text = label
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .secondaryLabel
            $0.width(60)
        }

        let valueView = UILabel().then {
            $0.text = value
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = .label
            $0.numberOfLines = 2
        }

        [iconView, labelView, valueView].forEach { addSubview($0) }

        iconView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }

        labelView.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        valueView.snp.makeConstraints {
            $0.leading.equalTo(labelView.snp.trailing).offset(8)
            $0.trailing.centerY.equalToSuperview()
        }

        snp.makeConstraints { $0.height.greaterThanOrEqualTo(32) }
    }
}

    // MARK: - MetaChipView

final class MetaChipView: UIView {

    init(title: String) {
        super.init(frame: .zero)
        setupUI(title: title)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String) {
        backgroundColor = .systemGray5
        layer.cornerRadius = 12

        let label = UILabel().then {
            $0.text = title
            $0.font = .systemFont(ofSize: 12)
            $0.textColor = .secondaryLabel
        }

        addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.top.bottom.equalToSuperview().inset(4)
        }
    }
}

    // MARK: - UILabel width helper

private extension UILabel {
    func width(_ value: CGFloat) {
        snp.makeConstraints { $0.width.equalTo(value) }
    }
}
