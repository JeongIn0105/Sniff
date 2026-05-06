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
        static let background = UIColor.systemBackground
        static let surface = UIColor.systemBackground
        static let border = UIColor(hex: "#E9E9E9")
        static let card = UIColor.systemBackground
        static let textPrimary = UIColor(hex: "#1F1F1F")
        static let textSecondary = UIColor(hex: "#7A7A7A")
        static let textMuted = UIColor(hex: "#B5B5B5")
    }

    private let viewModel: PerfumeDetailViewModel
    private let collectionRepository: CollectionRepositoryType
    private let tastingRecordRepository: TastingRecordRepositoryType
    private let disposeBag = DisposeBag()
    private var currentPerfume: Perfume?
    private var likedPerfumeIDs = Set<String>()
    private var ownedPerfumeIDs = Set<String>()
    private var ownedPerfumesByID = [String: CollectedPerfume]()
    private var currentOwnedPerfume: CollectedPerfume?
    private var hasTastingRecord = false
    private weak var presentedTastingFormController: UIViewController?
    private weak var toastView: UIView?
    private weak var controlledTabBar: UITabBar?
    private var bottomBarCenterYConstraint: Constraint?
    private weak var bottomBarHostView: UIView?
    private weak var presentedOwnedInfoEditController: UIViewController?
    private var ownedInfoCollapsedHeightConstraint: Constraint?
    private let collectionStateReloadInterval: TimeInterval = 20
    private var collectionStateLoadedAt: Date?
    private var isLoadingCollectionState = false

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

    deinit {
        restoreControlledTabBar()
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.contentInsetAdjustmentBehavior = .never
    }

    private let contentView = UIView()
    private let topBarView = UIView()
    private let heroSectionView = UIView()
    private let infoSectionView = UIView()
    private let usageSectionView = SectionContainerView()
    private let accordsSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.accords)
    private let notesSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.notes)
    private let ownedInfoSectionView = UIView()
    private let seasonSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.season)
    private let occasionSectionView = SectionContainerView(title: AppStrings.UIKitScreens.PerfumeDetail.occasion)
    private let bottomBarView = UIView().then {
        $0.backgroundColor = .clear
        $0.isOpaque = false
    }

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

    private let usageInfoView = UsageInfoView()
    private let accordListView = ScentFamilyListView()
    private let notesView = DetailNotesView()
    private let ownedInfoCardView = OwnedPerfumeInfoCardView()
    private let seasonChipsView = SeasonSelectionView()
    private let occasionChipsView = SeasonSelectionView()

    private let addTastingButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.PerfumeDetail.addTasting, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = Palette.textPrimary
        $0.layer.cornerRadius = 12
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.color = Palette.textPrimary
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard navigationController?.topViewController === self || navigationController == nil else { return }
        attachBottomBarToTabBarHostIfNeeded()
        updateBottomBarPosition()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setTabBarHidden(true, animated: false)
        attachBottomBarToTabBarHostIfNeeded()
        loadLikedPerfumes()
        refreshTastingRecordState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isLeavingDetailFlow else {
            bottomBarView.removeFromSuperview()
            bottomBarHostView = nil
            setTabBarHidden(false, animated: false)
            return
        }

        if let transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { context in
                if context.isCancelled {
                    self.setTabBarHidden(true, animated: false)
                    self.attachBottomBarToTabBarHostIfNeeded()
                    self.updateBottomBarPosition()
                } else {
                    self.bottomBarView.removeFromSuperview()
                    self.bottomBarHostView = nil
                    self.setTabBarHidden(false, animated: false)
                }
            }
        } else {
            bottomBarView.removeFromSuperview()
            bottomBarHostView = nil
            setTabBarHidden(false, animated: false)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard view.window == nil, !isStillInNavigationStack else { return }
        bottomBarView.removeFromSuperview()
        bottomBarHostView = nil
        setTabBarHidden(false, animated: false)
    }

    private func setupUI() {
        view.backgroundColor = Palette.background

        [topBarView, scrollView, loadingIndicator].forEach { view.addSubview($0) }
        view.bringSubviewToFront(topBarView)
        scrollView.addSubview(contentView)

        [
            heroSectionView,
            infoSectionView,
            usageSectionView,
            accordsSectionView,
            notesSectionView,
            ownedInfoSectionView,
            seasonSectionView,
            occasionSectionView
        ].forEach { contentView.addSubview($0) }

        topBarView.addSubview(backButton)
        topBarView.addSubview(likeButton)
        heroSectionView.addSubview(imageStageView)
        imageStageView.addSubview(bottleImageView)
        imageStageView.addSubview(imagePlaceholderLabel)
        [brandLabel, nameLabel].forEach { infoSectionView.addSubview($0) }
        usageSectionView.embed(usageInfoView)
        accordsSectionView.embed(accordListView)
        notesSectionView.embed(notesView)
        ownedInfoSectionView.addSubview(ownedInfoCardView)
        seasonSectionView.embed(seasonChipsView)
        occasionSectionView.embed(occasionChipsView)
        bottomBarView.addSubview(addTastingButton)
        ownedInfoCardView.onEditTapped = { [weak self] in
            self?.presentOwnedInfoEditSheet()
        }

        topBarView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(52)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(topBarView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
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

        likeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalTo(backButton)
            $0.size.equalTo(32)
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
            $0.bottom.equalToSuperview().offset(-18)
        }

        accordsSectionView.snp.makeConstraints {
            $0.top.equalTo(infoSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        notesSectionView.snp.makeConstraints {
            $0.top.equalTo(accordsSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        usageSectionView.snp.makeConstraints {
            $0.top.equalTo(notesSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        ownedInfoSectionView.snp.makeConstraints {
            $0.top.equalTo(usageSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            ownedInfoCollapsedHeightConstraint = $0.height.equalTo(0).constraint
        }

        ownedInfoCardView.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.size.equalTo(CGSize.zero)
        }

        seasonSectionView.snp.makeConstraints {
            $0.top.equalTo(ownedInfoSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        occasionSectionView.snp.makeConstraints {
            $0.top.equalTo(seasonSectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-40)
        }

        addTastingButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.bottom.equalToSuperview().inset(5)
            $0.height.equalTo(48)
        }

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        updateOwnedInfoSection(with: nil)
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

        output.onAddTastingRecord
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfume in
                self?.navigateToTastingRecord(perfume: perfume)
            })
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

        usageInfoView.configure(
            concentration: perfume.concentration,
            longevity: perfume.longevity,
            sillage: perfume.sillage
        )

        accordListView.configure(
            accords: perfume.mainAccords.map {
                ScentFamilyListView.Item(
                    rawValue: $0,
                    displayName: PerfumePresentationSupport.displayAccord($0)
                )
            }
        )

        notesView.configure(
            topNotes: PerfumePresentationSupport.displayNotes(perfume.topNotes ?? []),
            middleNotes: PerfumePresentationSupport.displayNotes(perfume.middleNotes ?? []),
            baseNotes: PerfumePresentationSupport.displayNotes(perfume.baseNotes ?? [])
        )

        seasonChipsView.configure(selectedSeasons: topSeasonNames(for: perfume))
        occasionChipsView.configure(texts: topOccasionNames(for: perfume))
        let collectionID = perfume.collectionDocumentID
        updateLikeUI(isLiked: likedPerfumeIDs.contains(collectionID))
        updateOwnedInfoSection(with: ownedPerfume(for: perfume))
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

    private func updateOwnedInfoSection(with ownedPerfume: CollectedPerfume?) {
        let shouldShow = ownedPerfume != nil
        currentOwnedPerfume = ownedPerfume
        ownedInfoSectionView.isHidden = !shouldShow
        ownedInfoCardView.isHidden = !shouldShow
        ownedInfoCardView.configure(with: ownedPerfume)

        if shouldShow {
            ownedInfoCollapsedHeightConstraint?.deactivate()
            ownedInfoCardView.snp.remakeConstraints {
                $0.top.equalToSuperview().offset(24)
                $0.leading.trailing.equalToSuperview().inset(20)
                $0.bottom.equalToSuperview().offset(-24)
            }
        } else {
            ownedInfoCardView.snp.remakeConstraints {
                $0.top.leading.equalToSuperview()
                $0.size.equalTo(CGSize.zero)
            }
            ownedInfoCollapsedHeightConstraint?.activate()
        }
    }

    private func ownedPerfume(for perfume: Perfume) -> CollectedPerfume? {
        if let item = ownedPerfumesByID[perfume.collectionDocumentID] {
            return item
        }

        let targetKey = PerfumePresentationSupport.recordKey(
            perfumeName: perfume.name,
            brandName: perfume.brand
        )
        return ownedPerfumesByID.values.first {
            PerfumePresentationSupport.recordKey(
                perfumeName: $0.name,
                brandName: $0.brand
            ) == targetKey
        }
    }

    private func presentOwnedInfoEditSheet() {
        guard let ownedPerfume = currentOwnedPerfume else { return }
        guard ownedPerfume.canEditRegistrationInfo else {
            showToast(message: "보유 정보 수정 가능 횟수를 모두 사용했어요.")
            return
        }

        let sheetView = OwnedPerfumeEditSheetView(
            perfume: ownedPerfume,
            onSave: { [weak self] info in
                guard let self else { return }
                self.saveOwnedInfo(info, sourceViewController: self.presentedOwnedInfoEditController)
            },
            onCancel: { [weak self] in
                self?.presentedOwnedInfoEditController?.dismiss(animated: true)
                self?.presentedOwnedInfoEditController = nil
            },
            onDelete: { [weak self] in
                guard let self else { return }
                self.deleteOwnedPerfume(sourceViewController: self.presentedOwnedInfoEditController)
            }
        )
        let hostingController = UIHostingController(rootView: sheetView)
        hostingController.modalPresentationStyle = .pageSheet
        if let sheetPresentationController = hostingController.sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.preferredCornerRadius = 28
        }
        presentedOwnedInfoEditController = hostingController
        present(hostingController, animated: true)
    }

    private func saveOwnedInfo(
        _ registrationInfo: CollectedPerfumeRegistrationInfo,
        sourceViewController: UIViewController?
    ) {
        guard let ownedPerfume = currentOwnedPerfume else { return }

        collectionRepository
            .updateCollectedPerfumeRegistration(id: ownedPerfume.id, registrationInfo: registrationInfo)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [weak self, weak sourceViewController] in
                    guard let self else { return }
                    let updatedPerfume = self.updatedOwnedPerfume(
                        ownedPerfume,
                        registrationInfo: registrationInfo
                    )
                    self.ownedPerfumesByID[updatedPerfume.id] = updatedPerfume
                    self.ownedPerfumeIDs.insert(updatedPerfume.id)
                    self.updateOwnedInfoSection(with: updatedPerfume)
                    self.notifyCollectionChanged(scope: .owned)
                    sourceViewController?.dismiss(animated: true) {
                        self.presentedOwnedInfoEditController = nil
                        self.showToast(message: "보유 정보가 저장됐어요.")
                    }
                },
                onError: { [weak sourceViewController] error in
                    Self.presentEditMutationError(error, from: sourceViewController)
                }
            )
            .disposed(by: disposeBag)
    }

    private func deleteOwnedPerfume(sourceViewController: UIViewController?) {
        guard let ownedPerfume = currentOwnedPerfume else { return }

        collectionRepository
            .deleteCollectedPerfume(id: ownedPerfume.id)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [weak self, weak sourceViewController] in
                    guard let self else { return }
                    self.ownedPerfumesByID.removeValue(forKey: ownedPerfume.id)
                    self.ownedPerfumeIDs.remove(ownedPerfume.id)
                    self.updateOwnedInfoSection(with: nil)
                    self.notifyCollectionChanged(scope: .owned)
                    sourceViewController?.dismiss(animated: true) {
                        self.presentedOwnedInfoEditController = nil
                        self.showToast(message: "보유 향수에서 해제됐어요.")
                    }
                },
                onError: { [weak sourceViewController] error in
                    Self.presentEditMutationError(error, from: sourceViewController)
                }
            )
            .disposed(by: disposeBag)
    }

    private func updatedOwnedPerfume(
        _ perfume: CollectedPerfume,
        registrationInfo: CollectedPerfumeRegistrationInfo
    ) -> CollectedPerfume {
        CollectedPerfume(
            id: perfume.id,
            name: perfume.name,
            brand: perfume.brand,
            imageUrl: perfume.imageUrl,
            mainAccords: perfume.mainAccords,
            accordStrengths: perfume.accordStrengths,
            memo: registrationInfo.memo,
            createdAt: perfume.createdAt,
            topNotes: perfume.topNotes,
            middleNotes: perfume.middleNotes,
            baseNotes: perfume.baseNotes,
            generalNotes: perfume.generalNotes,
            seasonRanking: perfume.seasonRanking,
            concentration: perfume.concentration,
            longevity: perfume.longevity,
            sillage: perfume.sillage,
            usageStatus: registrationInfo.usageStatus,
            usageFrequency: registrationInfo.usageFrequency,
            preferenceLevel: registrationInfo.preferenceLevel,
            registrationEditCount: min(
                perfume.registrationEditCount + 1,
                CollectedPerfumeEditPolicy.maxRegistrationEditCount
            )
        )
    }

    private static func presentEditMutationError(
        _ error: Error,
        from sourceViewController: UIViewController?
    ) {
        let message: String
        if let firestoreError = error as? FirestoreServiceError {
            message = firestoreError.localizedDescription
        } else {
            message = "잠시 후 다시 시도해주세요."
        }
        let alert = UIAlertController(
            title: AppStrings.UIKitScreens.error,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
        sourceViewController?.present(alert, animated: true)
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

    private func topOccasionNames(for perfume: Perfume) -> [String] {
        let rankedOccasions = perfume.occasionRanking
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            .prefix(2)
            .map(\.name)

        let occasions = rankedOccasions.isEmpty ? (perfume.situation ?? []) : Array(rankedOccasions)
        return occasions.map(displayOccasion)
    }

    private func displayOccasion(_ occasion: String) -> String {
        let normalized = occasion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let displayMap: [String: String] = [
            "daily": "데일리",
            "day": "낮",
            "night": "밤",
            "date": "데이트",
            "office": "출근",
            "work": "출근",
            "school": "학교",
            "weekend": "주말",
            "travel": "여행",
            "casual": "캐주얼",
            "formal": "포멀",
            "party": "파티",
            "sport": "운동",
            "gym": "운동"
        ]
        return displayMap[normalized] ?? occasion
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        scrollView.isHidden = isLoading
    }

    private func attachBottomBarToTabBarHostIfNeeded() {
        guard let hostView = tabBarController?.view ?? navigationController?.view ?? view else { return }
        guard bottomBarHostView !== hostView else {
            hostView.bringSubviewToFront(bottomBarView)
            return
        }

        bottomBarView.removeFromSuperview()
        hostView.addSubview(bottomBarView)
        hostView.bringSubviewToFront(bottomBarView)
        bottomBarHostView = hostView

        bottomBarView.snp.remakeConstraints {
            $0.leading.trailing.equalToSuperview()
            bottomBarCenterYConstraint = $0.centerY.equalToSuperview().constraint
            $0.height.equalTo(58)
        }
    }

    private func updateBottomBarPosition() {
        guard let hostView = bottomBarHostView ?? bottomBarView.superview else { return }

        if let tabBar = tabBarController?.tabBar ?? controlledTabBar,
           let tabBarSuperview = tabBar.superview {
            let tabBarFrame = hostView.convert(tabBar.frame, from: tabBarSuperview)
            bottomBarCenterYConstraint?.update(offset: tabBarFrame.midY - hostView.bounds.midY)
            return
        }

        let fallbackMidY = hostView.bounds.height - hostView.safeAreaInsets.bottom - 24
        bottomBarCenterYConstraint?.update(offset: fallbackMidY - hostView.bounds.midY)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func likeButtonTapped() {
        toggleLike()
    }

    private func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard let tabBar = tabBarController?.tabBar ?? controlledTabBar else { return }
        controlledTabBar = tabBar
        let targetAlpha: CGFloat = hidden ? 0 : 1
        guard tabBar.isHidden != hidden || tabBar.alpha != targetAlpha else { return }

        tabBar.layer.removeAllAnimations()
        let changes = {
            tabBar.alpha = targetAlpha
        }

        if animated {
            if !hidden {
                tabBar.isHidden = false
            }
            UIView.animate(withDuration: 0.2, animations: changes) { _ in
                tabBar.isHidden = hidden
            }
        } else {
            if !hidden {
                tabBar.isHidden = false
            }
            changes()
            tabBar.isHidden = hidden
        }
    }

    private var isLeavingDetailFlow: Bool {
        isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true
    }

    private var isStillInNavigationStack: Bool {
        navigationController?.viewControllers.contains(self) == true
    }

    private func restoreControlledTabBar() {
        guard let controlledTabBar else { return }
        controlledTabBar.alpha = 1
        controlledTabBar.isHidden = false
    }

    private func navigateToTastingRecord(perfume: Perfume) {
        let formView = TastingNoteSceneFactory.makeFormView(
            initialPerfume: perfume,
            isOwnedPerfumeContext: ownedPerfumeIDs.contains(perfume.collectionDocumentID)
        ) { [weak self] perfumeName in
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
        hostingController.hidesBottomBarWhenPushed = false
        bottomBarView.removeFromSuperview()
        bottomBarHostView = nil
        setTabBarHidden(false, animated: false)
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
            $0.bottom.equalTo(addTastingButton.snp.top).offset(-12)
        }

        container.alpha = 0
        UIView.animate(withDuration: 0.2) {
            container.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 2.8, options: [.curveEaseInOut]) {
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
        guard shouldReloadCollectionState else { return }
        isLoadingCollectionState = true
        collectionStateLoadedAt = Date()

        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] items in
                    guard let self else { return }
                    self.likedPerfumeIDs = Set(items.map(\.id))
                    if let perfume = self.currentPerfume {
                        self.updateLikeUI(isLiked: self.likedPerfumeIDs.contains(perfume.collectionDocumentID))
                    }
                    self.isLoadingCollectionState = false
                },
                onFailure: { [weak self] error in
                    self?.isLoadingCollectionState = false
                    #if DEBUG
                    print("[PerfumeDetail] fetchLikedPerfumes failed: \(error)")
                    #endif
                }
            )
            .disposed(by: disposeBag)

        collectionRepository.fetchCollection()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] items in
                    guard let self else { return }
                    self.ownedPerfumeIDs = Set(items.map(\.id))
                    self.ownedPerfumesByID = items.reduce(into: [String: CollectedPerfume]()) { result, item in
                        result[item.id] = item
                    }
                    if let perfume = self.currentPerfume {
                        self.updateOwnedInfoSection(with: self.ownedPerfume(for: perfume))
                    }
                    self.isLoadingCollectionState = false
                },
                onFailure: { [weak self] error in
                    self?.isLoadingCollectionState = false
                    #if DEBUG
                    print("[PerfumeDetail] fetchCollection failed: \(error)")
                    #endif
                }
            )
            .disposed(by: disposeBag)
    }

    private var shouldReloadCollectionState: Bool {
        guard !isLoadingCollectionState else { return false }
        guard let collectionStateLoadedAt else { return true }
        return Date().timeIntervalSince(collectionStateLoadedAt) > collectionStateReloadInterval
    }

    private func toggleLike() {
        guard let perfume = currentPerfume else { return }

        let collectionID = perfume.collectionDocumentID
        let wasLiked = likedPerfumeIDs.contains(collectionID)
        updateLikeState(for: collectionID, isLiked: !wasLiked)
        likeButton.isEnabled = false

        if wasLiked {
            collectionRepository.deleteLikedPerfume(id: collectionID)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.likeButton.isEnabled = true
                    self?.notifyCollectionChanged(scope: .liked)
                }, onError: { [weak self] error in
                    self?.likeButton.isEnabled = true
                    self?.updateLikeState(for: collectionID, isLiked: wasLiked)
                    self?.presentMutationError(error)
                })
                .disposed(by: disposeBag)
        } else {
            collectionRepository.saveLikedPerfume(perfume)
                .observe(on: MainScheduler.instance)
                .subscribe(onCompleted: { [weak self] in
                    self?.likeButton.isEnabled = true
                    self?.notifyCollectionChanged(scope: .liked)
                }, onError: { [weak self] error in
                    self?.likeButton.isEnabled = true
                    self?.updateLikeState(for: collectionID, isLiked: wasLiked)
                    self?.presentMutationError(error)
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

    private func updateLikeUI(isLiked: Bool) {
        PerfumeHeartStyle.applyState(to: likeButton, isLiked: isLiked)
    }

    private func refreshTastingRecordState() {
        guard let perfume = currentPerfume else { return }

        tastingRecordRepository.fetchTastingRecords()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] records in
                guard let self else { return }
                let keys = PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: perfume.name,
                    brandName: perfume.brand
                )
                self.hasTastingRecord = records.contains {
                    !keys.isDisjoint(with: PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: $0.perfumeName,
                        brandName: $0.brandName
                    ))
                }
                self.updateTastingButtonUI()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func updateTastingButtonUI() {
        addTastingButton.setTitle(AppStrings.UIKitScreens.PerfumeDetail.addTasting, for: .normal)
    }

    private func presentMutationError(_ error: Error) {
        #if DEBUG
        print("[PerfumeDetail] mutation error: \(error)")
        print("[PerfumeDetail] mutation error (NSError): \((error as NSError).domain) code=\((error as NSError).code) userInfo=\((error as NSError).userInfo)")
        #endif
        if let limitError = error as? CollectionUsageLimitError {
            showToast(message: limitError.localizedDescription)
        } else if error is FirestoreServiceError {
            showErrorAlert(message: error.localizedDescription)
        } else {
            showErrorAlert(message: "잠시 후 다시 시도해주세요.")
        }
    }

    private func notifyCollectionChanged(scope: PerfumeCollectionChangeScope) {
        NotificationCenter.default.postPerfumeCollectionDidChange(scope: scope)
    }

    private func navigateToMyPage() {
        setTabBarHidden(false, animated: false)
        MainTabRouter.shared.select(.my)
    }
}
