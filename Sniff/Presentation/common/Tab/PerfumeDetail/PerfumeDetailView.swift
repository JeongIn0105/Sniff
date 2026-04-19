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

    enum Palette {
        static let background = UIColor(hex: "#2E2C29")
        static let surface = UIColor(hex: "#33312E")
        static let border = UIColor(hex: "#4B4740")
        static let card = UIColor(hex: "#252421")
        static let textPrimary = UIColor(hex: "#F4F1EA")
        static let textSecondary = UIColor(hex: "#D2CCC1")
        static let textMuted = UIColor(hex: "#A9A295")
    }

    private let viewModel: PerfumeDetailViewModel
    private let collectionRepository: CollectionRepositoryType
    private let disposeBag = DisposeBag()
    private var currentPerfume: Perfume?
    private var likedPerfumeIDs = Set<String>()

    private let addTastingRecordRelay = PublishRelay<Void>()

    init(
        viewModel: PerfumeDetailViewModel,
        collectionRepository: CollectionRepositoryType = CollectionRepository()
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.contentInsetAdjustmentBehavior = .never
    }

    private let contentView = UIView()
    private let topBarView = UIView()
    private let heroSectionView = UIView()
    private let infoSectionView = UIView()
    private let usageSectionView = SectionContainerView(title: "사용감")
    private let accordsSectionView = SectionContainerView(title: "Main 어코드")
    private let notesSectionView = SectionContainerView(title: "노트")
    private let seasonSectionView = SectionContainerView(title: "계절")
    private let bottomBarView = UIView()

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        $0.tintColor = Palette.textPrimary
    }

    private let gridButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "square.grid.2x2"), for: .normal)
        $0.tintColor = Palette.textPrimary
    }

    private let imageStageView = UIView().then {
        $0.backgroundColor = .clear
    }

    private let bottleImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
        $0.tintColor = Palette.textMuted
    }

    private let likeButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.setImage(UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate), for: .selected)
        $0.tintColor = .white
        $0.backgroundColor = UIColor(hex: "#3B3934")
        $0.layer.cornerRadius = 18
        $0.layer.borderWidth = 1
        $0.layer.borderColor = Palette.border.cgColor
    }

    private let brandLabel = UILabel().then {
        $0.font = UIFont(name: "Georgia", size: 15) ?? .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = Palette.textSecondary
    }

    private let nameLabel = UILabel().then {
        $0.font = UIFont(name: "Georgia-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        $0.textColor = Palette.textPrimary
        $0.numberOfLines = 0
    }

    private let concentrationLabel = UILabel().then {
        $0.font = UIFont(name: "Georgia", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = Palette.textSecondary
        $0.numberOfLines = 1
    }

    private let topMoodChipsView = ChipWrapView(style: .outline)
    private let usageInfoView = UsageInfoView()
    private let accordChipsView = ChipWrapView(style: .mixed)
    private let notesView = DetailNotesView()
    private let seasonChipsView = SeasonSelectionView()

    private let addCollectionButton = UIButton(type: .system).then {
        $0.setTitle("보유 향수 등록", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        $0.setTitleColor(Palette.textPrimary, for: .normal)
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = Palette.border.cgColor
    }

    private let addTastingButton = UIButton(type: .system).then {
        $0.setTitle("시향기록 남기기", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.setTitleColor(Palette.background, for: .normal)
        $0.backgroundColor = UIColor(hex: "#F3F0EA")
        $0.layer.cornerRadius = 12
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.color = .white
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadLikedPerfumes()
    }

    private func setupUI() {
        view.backgroundColor = Palette.background

        [topBarView, scrollView, bottomBarView, loadingIndicator].forEach { view.addSubview($0) }
        scrollView.addSubview(contentView)

        [
            heroSectionView,
            infoSectionView,
            usageSectionView,
            accordsSectionView,
            notesSectionView,
            seasonSectionView
        ].forEach { contentView.addSubview($0) }

        [backButton, gridButton].forEach { topBarView.addSubview($0) }
        heroSectionView.addSubview(imageStageView)
        imageStageView.addSubview(bottleImageView)
        imageStageView.addSubview(likeButton)
        [brandLabel, nameLabel, concentrationLabel, topMoodChipsView].forEach { infoSectionView.addSubview($0) }
        usageSectionView.embed(usageInfoView)
        accordsSectionView.embed(accordChipsView)
        notesSectionView.embed(notesView)
        seasonSectionView.embed(seasonChipsView)
        [addCollectionButton, addTastingButton].forEach { bottomBarView.addSubview($0) }

        topBarView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(topBarView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomBarView.snp.top)
        }

        bottomBarView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(116)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }

        gridButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(28)
        }

        heroSectionView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(320)
        }

        imageStageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-12)
        }

        bottleImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        likeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-18)
            $0.bottom.equalToSuperview().offset(-18)
            $0.size.equalTo(42)
        }

        infoSectionView.snp.makeConstraints {
            $0.top.equalTo(heroSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        brandLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        concentrationLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        topMoodChipsView.snp.makeConstraints {
            $0.top.equalTo(concentrationLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-18)
        }

        usageSectionView.snp.makeConstraints {
            $0.top.equalTo(infoSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        accordsSectionView.snp.makeConstraints {
            $0.top.equalTo(usageSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        notesSectionView.snp.makeConstraints {
            $0.top.equalTo(accordsSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        seasonSectionView.snp.makeConstraints {
            $0.top.equalTo(notesSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-24)
        }

        bottomBarView.backgroundColor = Palette.background
        bottomBarView.layer.borderWidth = 1
        bottomBarView.layer.borderColor = Palette.border.cgColor

        addCollectionButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(14)
            $0.height.equalTo(46)
            $0.width.equalTo(110)
        }

        addTastingButton.snp.makeConstraints {
            $0.leading.equalTo(addCollectionButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalTo(addCollectionButton)
            $0.height.equalTo(46)
        }

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }

    private func bind() {
        let input = PerfumeDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            addToCollectionTap: .empty(),
            addTastingRecordTap: addTastingRecordRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.isLoading
            .drive(onNext: { [weak self] loading in
                loading ? self?.loadingIndicator.startAnimating() : self?.loadingIndicator.stopAnimating()
                self?.scrollView.isHidden = loading
            })
            .disposed(by: disposeBag)

        output.perfume
            .compactMap { $0 }
            .drive(onNext: { [weak self] perfume in
                self?.configure(with: perfume)
            })
            .disposed(by: disposeBag)

        output.errorMessage
            .compactMap { $0 }
            .drive(onNext: { [weak self] message in
                self?.showErrorAlert(message: message)
            })
            .disposed(by: disposeBag)

        output.onAddTastingRecord
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfume in
                self?.navigateToTastingRecord(perfume: perfume)
            })
            .disposed(by: disposeBag)

        addCollectionButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.toggleLike()
            })
            .disposed(by: disposeBag)

        addTastingButton.rx.tap
            .bind(to: addTastingRecordRelay)
            .disposed(by: disposeBag)
    }

    private func configure(with perfume: Perfume) {
        currentPerfume = perfume
        title = perfume.name

        bottleImageView.image = UIImage(systemName: "cube.transparent")
        if let urlStr = perfume.imageUrl, let url = URL(string: urlStr) {
            bottleImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "cube.transparent"),
                options: [.transition(.fade(0.2))]
            )
        }

        brandLabel.text = perfume.brand
        nameLabel.text = perfume.name
        concentrationLabel.text = formattedConcentration(perfume.concentration)

        let moodTags = perfume.mainAccords.prefix(3).map { $0.lowercased() }
        topMoodChipsView.configure(
            texts: moodTags,
            highlightedIndices: Set<Int>(),
            colorPalette: Palette.self
        )

        usageInfoView.configure(
            longevity: localizedLongevity(perfume.longevity ?? "-"),
            sillage: localizedSillage(perfume.sillage ?? "-")
        )

        accordChipsView.configure(
            texts: perfume.mainAccords.map { $0.lowercased() },
            highlightedIndices: Set<Int>(),
            colorPalette: Palette.self
        )

        notesView.configure(
            topNotes: perfume.topNotes ?? [],
            middleNotes: perfume.middleNotes ?? [],
            baseNotes: perfume.baseNotes ?? []
        )

        let topSeasons = perfume.seasonRanking
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(2)
            .map(\.name)

        seasonChipsView.configure(
            selectedSeasons: topSeasons.isEmpty ? (perfume.season ?? []) : Array(topSeasons)
        )
        updateLikeUI(isLiked: likedPerfumeIDs.contains(perfume.id))
    }

    private func formattedConcentration(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "-" }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch normalized {
            case "parfum", "perfume":
                return "퍼퓸"
            case "edp", "eau de parfum":
                return "오 드 퍼퓸"
            case "edt", "eau de toilette":
                return "오 드 뚜왈렛"
            case "edc", "eau de cologne", "cologne":
                return "오 드 코롱"
            case "fraiche", "eau fraiche":
                return "오 프레쉬"
            default:
                break
        }

        return value.replacingOccurrences(of: "eau de ", with: "오 드 ")
            .replacingOccurrences(of: "parfum", with: "퍼퓸")
            .replacingOccurrences(of: "toilette", with: "뚜왈렛")
            .replacingOccurrences(of: "cologne", with: "코롱")
            .capitalized
    }

    private func localizedLongevity(_ value: String) -> String {
        switch value.lowercased() {
            case "very weak":         return "매우 약함"
            case "weak":              return "약함"
            case "moderate":          return "보통"
            case "long lasting":      return "오래 지속됨"
            case "very long lasting": return "매우 오래 지속됨"
            default:                  return value
        }
    }

    private func localizedSillage(_ value: String) -> String {
        switch value.lowercased() {
            case "intimate":     return "은은함"
            case "soft":         return "약함"
            case "moderate":     return "보통"
            case "strong":       return "강함"
            case "enormous":     return "매우 강함"
            case "overwhelming": return "압도적"
            default:             return value
        }
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func likeButtonTapped() {
        toggleLike()
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

    private func loadLikedPerfumes() {
        collectionRepository.fetchCollection()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                guard let self else { return }
                self.likedPerfumeIDs = Set(items.map(\.id))
                if let perfume = self.currentPerfume {
                    self.updateLikeUI(isLiked: self.likedPerfumeIDs.contains(perfume.id))
                }
            })
            .disposed(by: disposeBag)
    }

    private func toggleLike() {
        guard let perfume = currentPerfume else { return }

        if likedPerfumeIDs.contains(perfume.id) {
            collectionRepository.deleteCollectedPerfume(id: perfume.id)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.likedPerfumeIDs.remove(perfume.id)
                    self?.updateLikeUI(isLiked: false)
                })
                .disposed(by: disposeBag)
        } else {
            collectionRepository.saveCollectedPerfume(perfume, memo: nil)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.likedPerfumeIDs.insert(perfume.id)
                    self?.updateLikeUI(isLiked: true)
                })
                .disposed(by: disposeBag)
        }
    }

    private func updateLikeUI(isLiked: Bool) {
        likeButton.isSelected = isLiked
        let title = isLiked ? "보유 향수 해제" : "보유 향수 등록"
        addCollectionButton.setTitle(title, for: .normal)
    }
}

private final class SectionContainerView: UIView {
    private let titleLabel = UILabel().then {
        $0.font = UIFont(name: "Georgia-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = PerfumeDetailViewController.Palette.textPrimary
    }
    private let divider = UIView().then {
        $0.backgroundColor = PerfumeDetailViewController.Palette.border
    }
    private let contentContainer = UIView()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = PerfumeDetailViewController.Palette.surface
        titleLabel.text = title
        [divider, titleLabel, contentContainer].forEach { addSubview($0) }

        divider.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        contentContainer.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func embed(_ view: UIView) {
        contentContainer.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

private final class UsageInfoView: UIView {
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

    func configure(longevity: String, sillage: String) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stackView.addArrangedSubview(makeRow(title: "지속력", value: longevity))
        stackView.addArrangedSubview(makeRow(title: "확산력", value: sillage))
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

private final class DetailNotesView: UIView {
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
        stackView.addArrangedSubview(NoteLineView(title: "탑", notes: topNotes))
        stackView.addArrangedSubview(NoteLineView(title: "미들", notes: middleNotes))
        stackView.addArrangedSubview(NoteLineView(title: "베이스", notes: baseNotes))
    }
}

private final class NoteLineView: UIView {
    init(title: String, notes: [String]) {
        super.init(frame: .zero)

        let titleLabel = UILabel().then {
            $0.text = title
            $0.font = UIFont(name: "Georgia", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = PerfumeDetailViewController.Palette.textSecondary
        }

        let labelWidth: CGFloat = 44
        let sectionInsets: CGFloat = 40   // leading 20 + trailing 20
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

private final class SeasonSelectionView: UIView {
    private let displayMap: [String: String] = [
        "spring": "봄",
        "summer": "여름",
        "fall": "가을",
        "winter": "겨울"
    ]
    private var visibleTexts: [String] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(selectedSeasons: [String]) {
        visibleTexts = Array(selectedSeasons.prefix(2)).map { displayMap[$0.lowercased()] ?? $0 }
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

private final class ChipWrapView: UIView {
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
        self.subviews.forEach { $0.removeFromSuperview() }
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
        let height: CGFloat = 30

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
        let height: CGFloat = 30

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
            $0.font = UIFont(name: "Georgia-Bold", size: 13) ?? .systemFont(ofSize: 13, weight: .bold)
            $0.textColor = PerfumeDetailViewController.Palette.textSecondary
        }

        let container = UIView()
        let shouldFill = style == .mixed && highlighted
        container.backgroundColor = shouldFill ? PerfumeDetailViewController.Palette.card : .clear
        container.layer.cornerRadius = 19
        container.layer.borderWidth = 1
        container.layer.borderColor = PerfumeDetailViewController.Palette.border.cgColor
        container.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
        return container
    }

    private func chipWidth(for text: String) -> CGFloat {
        let font = UIFont(name: "Georgia-Bold", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .bold)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return ceil(textWidth) + 24
    }
}
