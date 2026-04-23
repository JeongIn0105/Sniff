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
import SwiftUI

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
    private var ownedPerfumeIDs = Set<String>()
    private weak var presentedTastingFormController: UIViewController?

    private let addCollectionRelay = PublishRelay<Void>()
    private let addTastingRecordRelay = PublishRelay<Void>()

    init(
        viewModel: PerfumeDetailViewModel,
        collectionRepository: CollectionRepositoryType
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
    private let accordsSectionView = SectionContainerView(title: "향 계열")
    private let notesSectionView = SectionContainerView(title: "노트 피라미드")
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

    private let imagePlaceholderLabel = UILabel().then {
        $0.text = "이미지 준비중입니다"
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = Palette.textMuted
        $0.textAlignment = .center
        $0.numberOfLines = 2
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
    private let usageInfoView = UsageInfoView()
    private let accordChipsView = ChipWrapView(style: .mixed)
    private let notesView = DetailNotesView()
    private let seasonChipsView = SeasonSelectionView()

    private let addCollectionButton = UIButton(type: .system).then {
        $0.setTitle("향수 등록", for: .normal)
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
        imageStageView.addSubview(imagePlaceholderLabel)
        imageStageView.addSubview(likeButton)
        [brandLabel, nameLabel, concentrationLabel].forEach { infoSectionView.addSubview($0) }
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

        imagePlaceholderLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(24)
            $0.trailing.lessThanOrEqualToSuperview().offset(-24)
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
            addToCollectionTap: addCollectionRelay.asObservable(),
            addTastingRecordTap: addTastingRecordRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.isLoading
            .drive(onNext: { [weak self] loading in
                self?.updateLoadingState(loading)
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

        output.onAddToCollection
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.toggleOwnedCollection()
            })
            .disposed(by: disposeBag)

        output.onAddTastingRecord
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfume in
                self?.navigateToTastingRecord(perfume: perfume)
            })
            .disposed(by: disposeBag)

        addCollectionButton.rx.tap
            .bind(to: addCollectionRelay)
            .disposed(by: disposeBag)

        addTastingButton.rx.tap
            .bind(to: addTastingRecordRelay)
            .disposed(by: disposeBag)
    }

    private func configure(with perfume: Perfume) {
        currentPerfume = perfume
        title = perfume.name

        configureImage(using: perfume.imageUrl)

        brandLabel.text = perfume.brand
        nameLabel.text = perfume.name
        concentrationLabel.text = formattedConcentration(perfume.concentration)

        usageInfoView.configure(
            longevity: localizedLongevity(perfume.longevity ?? "-"),
            sillage: localizedSillage(perfume.sillage ?? "-")
        )

        let dominantAccordIndices = Set(
            perfume.mainAccords.enumerated().compactMap { index, accord in
                perfume.mainAccordStrengths[accord] == .dominant ? index : nil
            }
        )
        accordChipsView.configure(
            texts: perfume.mainAccords.map { formatAccord($0) },
            highlightedIndices: dominantAccordIndices,
            colorPalette: Palette.self
        )

        notesView.configure(
            topNotes: perfume.topNotes ?? [],
            middleNotes: perfume.middleNotes ?? [],
            baseNotes: perfume.baseNotes ?? []
        )

        seasonChipsView.configure(
            selectedSeasons: topSeasonNames(for: perfume)
        )
        updateLikeUI(isLiked: likedPerfumeIDs.contains(perfume.id))
        updateOwnedUI(isOwned: ownedPerfumeIDs.contains(perfume.id))
    }

    private func configureImage(using imageURL: String?) {
        bottleImageView.image = nil
        imagePlaceholderLabel.isHidden = false

        guard let imageURL, let url = URL(string: imageURL) else { return }

        bottleImageView.kf.setImage(
            with: url,
            options: [.transition(.fade(0.2))]
        ) { [weak self] result in
            switch result {
            case .success:
                self?.imagePlaceholderLabel.isHidden = true
            case .failure:
                self?.imagePlaceholderLabel.isHidden = false
            }
        }
    }

    private func topSeasonNames(for perfume: Perfume) -> [String] {
        let rankedSeasons = perfume.seasonRanking
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(2)
            .map(\.name)

        return rankedSeasons.isEmpty ? (perfume.season ?? []) : Array(rankedSeasons)
    }

    private func formatAccord(_ accord: String) -> String {
        accord
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        scrollView.isHidden = isLoading
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
        let formView = TastingNoteSceneFactory.makeFormView(initialPerfume: perfume) { [weak self] perfumeName in
            self?.showCompletionAlert(
                title: "시향 기록 저장 완료",
                message: "\(perfumeName) 시향 기록이 저장되었습니다."
            )
        }
        let hostingController = UIHostingController(rootView: formView)
        hostingController.modalPresentationStyle = .fullScreen
        presentedTastingFormController = hostingController
        present(hostingController, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showCompletionAlert(title: String, message: String) {
        let presentAlert = { [weak self] in
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }

        if let presentedTastingFormController {
            presentedTastingFormController.dismiss(animated: true) { [weak self] in
                self?.presentedTastingFormController = nil
                presentAlert()
            }
        } else {
            presentAlert()
        }
    }

    private func loadLikedPerfumes() {
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                guard let self else { return }
                self.likedPerfumeIDs = Set(items.map(\.id))
                if let perfume = self.currentPerfume {
                    self.updateLikeUI(isLiked: self.likedPerfumeIDs.contains(perfume.id))
                }
            })
            .disposed(by: disposeBag)

        collectionRepository.fetchCollection()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                guard let self else { return }
                self.ownedPerfumeIDs = Set(items.map(\.id))
                if let perfume = self.currentPerfume {
                    self.updateOwnedUI(isOwned: self.ownedPerfumeIDs.contains(perfume.id))
                }
            })
            .disposed(by: disposeBag)
    }

    private func toggleLike() {
        guard let perfume = currentPerfume else { return }

        if likedPerfumeIDs.contains(perfume.id) {
            collectionRepository.deleteLikedPerfume(id: perfume.id)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.updateLikeState(for: perfume.id, isLiked: false)
                })
                .disposed(by: disposeBag)
        } else {
            collectionRepository.saveLikedPerfume(perfume)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.updateLikeState(for: perfume.id, isLiked: true)
                })
                .disposed(by: disposeBag)
        }
    }

    private func updateLikeState(for perfumeID: String, isLiked: Bool) {
        if isLiked {
            likedPerfumeIDs.insert(perfumeID)
        } else {
            likedPerfumeIDs.remove(perfumeID)
        }
        updateLikeUI(isLiked: isLiked)
    }

    private func toggleOwnedCollection() {
        guard let perfume = currentPerfume else { return }

        if ownedPerfumeIDs.contains(perfume.id) {
            collectionRepository.deleteCollectedPerfume(id: perfume.id)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.updateOwnedState(for: perfume.id, isOwned: false)
                })
                .disposed(by: disposeBag)
        } else {
            collectionRepository.saveCollectedPerfume(perfume, memo: nil)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.updateOwnedState(for: perfume.id, isOwned: true)
                })
                .disposed(by: disposeBag)
        }
    }

    private func updateOwnedState(for perfumeID: String, isOwned: Bool) {
        if isOwned {
            ownedPerfumeIDs.insert(perfumeID)
        } else {
            ownedPerfumeIDs.remove(perfumeID)
        }
        updateOwnedUI(isOwned: isOwned)
    }

    private func updateLikeUI(isLiked: Bool) {
        likeButton.isSelected = isLiked
    }

    private func updateOwnedUI(isOwned: Bool) {
        let title = isOwned ? "향수 등록됨" : "향수 등록"
        addCollectionButton.setTitle(title, for: .normal)
    }
}
