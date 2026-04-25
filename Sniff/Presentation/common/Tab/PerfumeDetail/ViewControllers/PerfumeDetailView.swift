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
    private let tastingRecordRepository: TastingRecordRepositoryType
    private let disposeBag = DisposeBag()
    private var currentPerfume: Perfume?
    private var likedPerfumeIDs = Set<String>()
    private var ownedPerfumeIDs = Set<String>()
    private var hasTastingRecord = false
    private weak var presentedTastingFormController: UIViewController?
    private weak var toastView: UIView?

    private let addCollectionRelay = PublishRelay<Void>()
    private let addTastingRecordRelay = PublishRelay<Void>()

    init(
        viewModel: PerfumeDetailViewModel,
        collectionRepository: CollectionRepositoryType,
        tastingRecordRepository: TastingRecordRepositoryType
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
        self.tastingRecordRepository = tastingRecordRepository
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
    private let usageSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.usage)
    private let accordsSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.accords)
    private let notesSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.notes)
    private let seasonSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.season)
    private let bottomBarView = UIView()

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "arrow.left"), for: .normal)
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
        $0.text = AppStrings.UIKitScreens.PerfumeDetail.imagePlaceholder
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = Palette.textMuted
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private let likeButton = UIButton(type: .custom).then {
        PerfumeHeartStyle.configure($0)
        PerfumeHeartStyle.applyState(to: $0, isLiked: false)
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
    private let accordChipsView = ChipWrapView(style: .outline)
    private let notesView = DetailNotesView()
    private let seasonChipsView = SeasonSelectionView()

    private let addCollectionButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.PerfumeDetail.addCollection, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        $0.setTitleColor(Palette.textPrimary, for: .normal)
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = Palette.border.cgColor
    }

    private let addTastingButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.PerfumeDetail.addTasting, for: .normal)
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
        refreshTastingRecordState()
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

        topBarView.addSubview(backButton)
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
            $0.size.equalTo(32)
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
            .subscribe(onNext: { [weak self] in
                guard let self, let perfume = self.currentPerfume else { return }
                if self.hasTastingRecord {
                    self.navigateToTastingRecords(perfume: perfume)
                } else {
                    self.addTastingRecordRelay.accept(())
                }
            })
            .disposed(by: disposeBag)
    }

    private func configure(with perfume: Perfume) {
        currentPerfume = perfume
        title = PerfumePresentationSupport.displayPerfumeName(perfume.name)

        configureImage(using: perfume.imageUrl)

        brandLabel.text = PerfumePresentationSupport.displayBrand(perfume.brand)
        nameLabel.text = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        concentrationLabel.text = PerfumePresentationSupport.displayConcentration(perfume.concentration)

        usageInfoView.configure(
            longevity: PerfumePresentationSupport.displayLongevity(perfume.longevity),
            sillage: PerfumePresentationSupport.displaySillage(perfume.sillage)
        )

        let dominantAccordIndices = Set(
            perfume.mainAccords.enumerated().compactMap { index, accord in
                perfume.mainAccordStrengths[accord] == .dominant ? index : nil
            }
        )
        accordChipsView.configure(
            texts: perfume.mainAccords.map { PerfumePresentationSupport.displayAccord($0) },
            highlightedIndices: dominantAccordIndices,
            colorPalette: Palette.self
        )

        notesView.configure(
            topNotes: PerfumePresentationSupport.displayNotes(perfume.topNotes ?? []),
            middleNotes: PerfumePresentationSupport.displayNotes(perfume.middleNotes ?? []),
            baseNotes: PerfumePresentationSupport.displayNotes(perfume.baseNotes ?? [])
        )

        seasonChipsView.configure(selectedSeasons: topSeasonNames(for: perfume))
        updateLikeUI(isLiked: likedPerfumeIDs.contains(perfume.id))
        updateOwnedUI(isOwned: ownedPerfumeIDs.contains(perfume.id))
        updateTastingButtonUI()
    }

    private func configureImage(using imageURL: String?) {
        bottleImageView.image = nil
        imagePlaceholderLabel.isHidden = false

        guard let imageURL, let url = URL(string: imageURL) else { return }

        bottleImageView.kf.setImage(
            with: url,
            options: [.transition(.fade(0.2))]
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.imagePlaceholderLabel.isHidden = true
            case .failure:
                self.imagePlaceholderLabel.isHidden = false
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

        let seasons = rankedSeasons.isEmpty ? (perfume.season ?? []) : Array(rankedSeasons)
        return PerfumePresentationSupport.displaySeasons(seasons)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        scrollView.isHidden = isLoading
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func likeButtonTapped() {
        toggleLike()
    }

    private func navigateToTastingRecord(perfume: Perfume) {
        let formView = TastingNoteSceneFactory.makeFormView(initialPerfume: perfume) { [weak self] perfumeName in
            guard let self else { return }
            self.hasTastingRecord = true
            self.updateTastingButtonUI()
            if let presentedTastingFormController {
                presentedTastingFormController.dismiss(animated: true) {
                    self.presentedTastingFormController = nil
                    self.refreshTastingRecordState()
                    self.showToast(message: AppStrings.ViewModelMessages.TastingNote.saved(perfumeName))
                }
            }
        }
        let hostingController = UIHostingController(rootView: formView)
        hostingController.modalPresentationStyle = .fullScreen
        presentedTastingFormController = hostingController
        present(hostingController, animated: true)
    }

    private func navigateToTastingRecords(perfume: Perfume) {
        let scope = TastingNotePerfumeScope(
            perfumeName: perfume.name,
            brandName: perfume.brand
        )
        let tastingView = TastingNoteSceneFactory.makeListView(perfumeScope: scope)
        let hostingController = UIHostingController(rootView: tastingView)
        navigationController?.pushViewController(hostingController, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: AppStrings.UIKitScreens.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
        present(alert, animated: true)
    }

    private func showToast(message: String) {
        toastView?.removeFromSuperview()

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.86)
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2

        container.addSubview(label)
        view.addSubview(container)
        toastView = container

        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 13, left: 18, bottom: 13, right: 18))
        }

        container.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(bottomBarView.snp.top).offset(-12)
        }

        container.alpha = 0
        UIView.animate(withDuration: 0.2) {
            container.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 1.8, options: [.curveEaseInOut]) {
                container.alpha = 0
            } completion: { [weak container] _ in
                container?.removeFromSuperview()
            }
        }
    }

    private func showCompletionAlert(title: String, message: String) {
        let presentAlert = { [weak self] in
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
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

        let wasLiked = likedPerfumeIDs.contains(perfume.id)
        updateLikeState(for: perfume.id, isLiked: !wasLiked)
        likeButton.isEnabled = false

        if wasLiked {
            collectionRepository.deleteLikedPerfume(id: perfume.id)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.likeButton.isEnabled = true
                }, onError: { [weak self] error in
                    self?.likeButton.isEnabled = true
                    self?.updateLikeState(for: perfume.id, isLiked: wasLiked)
                    self?.showErrorAlert(message: error.localizedDescription)
                })
                .disposed(by: disposeBag)
        } else {
            collectionRepository.saveLikedPerfume(perfume)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.likeButton.isEnabled = true
                }, onError: { [weak self] error in
                    self?.likeButton.isEnabled = true
                    self?.updateLikeState(for: perfume.id, isLiked: wasLiked)
                    self?.showErrorAlert(message: error.localizedDescription)
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

        let wasOwned = ownedPerfumeIDs.contains(perfume.id)
        updateOwnedState(for: perfume.id, isOwned: !wasOwned)
        addCollectionButton.isEnabled = false

        if wasOwned {
            collectionRepository.deleteCollectedPerfume(id: perfume.id)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.addCollectionButton.isEnabled = true
                }, onError: { [weak self] error in
                    self?.addCollectionButton.isEnabled = true
                    self?.updateOwnedState(for: perfume.id, isOwned: wasOwned)
                    self?.showErrorAlert(message: error.localizedDescription)
                })
                .disposed(by: disposeBag)
        } else {
            collectionRepository.saveCollectedPerfume(perfume, memo: nil)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.addCollectionButton.isEnabled = true
                }, onError: { [weak self] error in
                    self?.addCollectionButton.isEnabled = true
                    self?.updateOwnedState(for: perfume.id, isOwned: wasOwned)
                    self?.showErrorAlert(message: error.localizedDescription)
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
        PerfumeHeartStyle.applyState(to: likeButton, isLiked: isLiked)
    }

    private func updateOwnedUI(isOwned: Bool) {
        let title = isOwned ? AppStrings.UIKitScreens.PerfumeDetail.addedCollection : AppStrings.UIKitScreens.PerfumeDetail.addCollection
        addCollectionButton.setTitle(title, for: .normal)
    }

    private func refreshTastingRecordState() {
        guard let perfume = currentPerfume else { return }

        tastingRecordRepository.fetchTastingRecords()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] records in
                guard let self else { return }
                let key = PerfumePresentationSupport.recordKey(
                    perfumeName: perfume.name,
                    brandName: perfume.brand
                )
                self.hasTastingRecord = records.contains {
                    PerfumePresentationSupport.recordKey(
                        perfumeName: $0.perfumeName,
                        brandName: $0.brandName
                    ) == key
                }
                self.updateTastingButtonUI()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func updateTastingButtonUI() {
        let title = hasTastingRecord ? "시향기로 이동" : AppStrings.UIKitScreens.PerfumeDetail.addTasting
        addTastingButton.setTitle(title, for: .normal)
    }
}
