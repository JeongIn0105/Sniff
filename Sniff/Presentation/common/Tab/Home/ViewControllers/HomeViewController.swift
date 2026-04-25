//
//  HomeViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import SwiftUI

final class HomeViewController: UIViewController {

    private enum Layout {
        static let horizontalInset: CGFloat = 20
        static let cardWidth: CGFloat = 154
        static let cardHeight: CGFloat = 256
        static let cardSpacing: CGFloat = 14
    }

    private let viewModel: HomeViewModel
    private let collectionRepository: CollectionRepositoryType
    private let disposeBag = DisposeBag()
    private var recommendations: [HomePerfumeItem] = []
    private var currentProfileItem: HomeViewModel.HomeProfileItem?
    private var currentBannerItem: HomeTasteBannerItem?
    private var likedPerfumeIDs = Set<String>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let topGradientView = HomeGradientView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.UIKitScreens.Home.title
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = .label
        return button
    }()

    private let profileHeroCard: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let profileTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 1, weight: .regular)
        label.textColor = .clear
        label.numberOfLines = 1
        return label
    }()

    private let profileChevronView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let profileHeadlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let profileSummaryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(white: 0.22, alpha: 0.82)
        label.numberOfLines = 3
        return label
    }()

    private let profileTagStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()

    private let recommendationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Home.recommendTitle
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let recommendationCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.cardSpacing
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private let guideContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.985, green: 0.984, blue: 0.982, alpha: 1)
        view.layer.cornerRadius = 18
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.08).cgColor
        return view
    }()

    private let guideIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "info.circle"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let guideLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.UIKitScreens.Home.guide
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = UIColor.secondaryLabel.withAlphaComponent(0.72)
        label.numberOfLines = 0
        return label
    }()

    init(
        viewModel: HomeViewModel,
        collectionRepository: CollectionRepositoryType
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLikedPerfumes()
    }
}

private extension HomeViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        recommendationCollectionView.delegate = self
        recommendationCollectionView.dataSource = self
        recommendationCollectionView.register(
            HomePerfumeCardCell.self,
            forCellWithReuseIdentifier: HomePerfumeCardCell.reuseIdentifier
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(topGradientView)

        [
            titleLabel,
            searchButton,
            profileHeroCard,
            recommendationTitleLabel,
            recommendationCollectionView,
            guideContainerView
        ].forEach { contentView.addSubview($0) }

        [profileTitleLabel, profileChevronView, profileHeadlineLabel, profileSummaryLabel, profileTagStack]
            .forEach { profileHeroCard.addSubview($0) }
        [guideIconView, guideLabel].forEach { guideContainerView.addSubview($0) }

        profileHeroCard.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(profileCardTapped))
        )
        profileHeroCard.isUserInteractionEnabled = true

        makeConstraints()
    }

    func makeConstraints() {
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        topGradientView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(profileHeroCard.snp.bottom).offset(20)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.equalToSuperview().offset(20)
        }

        searchButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.size.equalTo(28)
        }

        profileHeroCard.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(92)
            $0.leading.trailing.equalToSuperview()
        }

        profileTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
            $0.height.equalTo(0)
        }

        profileChevronView.snp.makeConstraints {
            $0.leading.greaterThanOrEqualTo(profileHeadlineLabel.snp.trailing).offset(6)
            $0.centerY.equalTo(profileHeadlineLabel)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
            $0.width.equalTo(10)
            $0.height.equalTo(14)
        }

        profileHeadlineLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualTo(profileChevronView.snp.leading).offset(-6)
        }

        profileSummaryLabel.snp.makeConstraints {
            $0.top.equalTo(profileHeadlineLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        profileTagStack.snp.makeConstraints {
            $0.top.equalTo(profileSummaryLabel.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
            $0.bottom.equalToSuperview()
        }

        recommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(profileHeroCard.snp.bottom).offset(44)
            $0.leading.equalToSuperview().offset(20)
        }

        recommendationCollectionView.snp.makeConstraints {
            $0.top.equalTo(recommendationTitleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.cardHeight)
        }

        guideContainerView.snp.makeConstraints {
            $0.top.equalTo(recommendationCollectionView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(24)
        }

        guideIconView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(14)
            $0.size.equalTo(16)
        }

        guideLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(14)
            $0.leading.equalTo(guideIconView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(14)
        }
    }

    @objc func profileCardTapped() {
        guard let item = currentProfileItem else { return }
        let profileVC = TasteProfileViewController(profileItem: item)
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

private extension HomeViewController {

    func bind() {
        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            perfumeRegisterTap: .never(),
            tastingNoteTap: .never(),
            reportTap: .never(),
            perfumeSelect: .never()
        )

        let output = viewModel.transform(input: input)

        bindBanner(output.banner)
        bindProfile(output.profile)
        bindRecommendations(output.recommendations)
        bindRoute(output.route)
        bindSearchButton()
    }

    func bindBanner(_ banner: Driver<HomeTasteBannerItem>) {
        banner
            .drive(with: self) { owner, item in
                owner.currentBannerItem = item
                owner.profileHeadlineLabel.text = item.title
                owner.profileSummaryLabel.text = item.summary
                owner.updateProfileTags(with: owner.currentProfileItem?.profile, banner: item)
            }
            .disposed(by: disposeBag)
    }

    func bindProfile(_ profile: Driver<HomeViewModel.HomeProfileItem?>) {
        profile
            .drive(with: self) { owner, item in
                guard let item else { return }
                owner.currentProfileItem = item
                if owner.currentBannerItem == nil {
                    owner.profileHeadlineLabel.text = item.profile.displayTitle
                    owner.profileSummaryLabel.text = item.profile.analysisSummary
                }
                owner.updateProfileTags(with: item.profile, banner: owner.currentBannerItem)
            }
            .disposed(by: disposeBag)
    }

    func bindRecommendations(_ recommendations: Driver<[HomePerfumeItem]>) {
        recommendations
            .drive(with: self) { owner, items in
                owner.recommendations = items
                owner.recommendationCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }

    func bindRoute(_ route: Signal<HomeRoute>) {
        route
            .emit(with: self) { owner, route in owner.handleRoute(route) }
            .disposed(by: disposeBag)
    }

    func bindSearchButton() {
        searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let searchViewController = SearchSceneFactory.makeSearchViewController(
                    dependencyContainer: AppDependencyContainer.shared,
                    showsRecentOnAppear: true
                )
                self?.navigationController?.pushViewController(searchViewController, animated: true)
            })
            .disposed(by: disposeBag)
    }

    func updateProfileTags(with profile: UserTasteProfile?, banner: HomeTasteBannerItem?) {
        profileTagStack.arrangedSubviews.forEach {
            profileTagStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        var tags: [String] = []
        if let profile {
            tags.append(contentsOf: Array(profile.displayFamilies.prefix(2)).map(displayName(for:)))
        } else if let banner, !banner.familyText.isEmpty {
            tags.append(contentsOf: banner.familyText.components(separatedBy: "·").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            })
        }

        if tags.isEmpty {
            tags = ["취향 분석", "추천 업데이트"]
        }

        for tag in Array(tags.prefix(2)) {
            profileTagStack.addArrangedSubview(makeTagLabel(text: tag))
        }
    }

    func makeTagLabel(text: String) -> UIView {
        let dotView = UIView()
        dotView.backgroundColor = ScentFamilyColor.color(for: text)
        dotView.layer.cornerRadius = 3

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(white: 0.42, alpha: 1)

        let stack = UIStackView(arrangedSubviews: [dotView, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6

        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        container.layer.cornerRadius = 13
        container.layer.cornerCurve = .continuous
        container.addSubview(stack)

        dotView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 6, height: 6))
        }

        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(7)
            $0.leading.trailing.equalToSuperview().inset(10)
        }

        return container
    }

    func displayName(for family: String) -> String {
        switch family {
        case "Soft Floral": return "소프트 플로럴"
        case "Floral": return "플로럴"
        case "Floral Amber": return "플로럴 앰버"
        case "Soft Amber": return "소프트 앰버"
        case "Amber": return "앰버"
        case "Woody Amber": return "우디 앰버"
        case "Woods": return "우디"
        case "Mossy Woods": return "모시 우즈"
        case "Dry Woods": return "드라이 우즈"
        case "Citrus": return "시트러스"
        case "Fruity": return "프루티"
        case "Green": return "그린"
        case "Water": return "워터리"
        case "Aromatic": return "아로마틱"
        default: return family
        }
    }
}

private extension HomeViewController {

    func handleRoute(_ route: HomeRoute) {
        switch route {
        case .perfumeRegister:
            presentAlert(AppStrings.UIKitScreens.Home.routePerfumeRegister)
        case .tastingNoteWrite:
            presentAlert(AppStrings.UIKitScreens.Home.routeTastingNote)
        case .tasteReport:
            presentAlert(AppStrings.UIKitScreens.Home.routeTasteReport)
        case .perfumeDetail(let perfume):
            navigateToPerfumeDetail(perfume)
        }
    }

    func navigateToPerfumeDetail(_ perfume: Perfume) {
        if perfume.id.hasPrefix("local-") {
            presentAlert(AppStrings.UIKitScreens.Home.sampleCard)
            return
        }

        let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
        present(alert, animated: true)
    }
}

private extension HomeViewController {

    func loadLikedPerfumes() {
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.likedPerfumeIDs = Set(items.map(\.id))
                self?.recommendationCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    func saveLike(for item: HomePerfumeItem) {
        let perfume = Perfume(
            id: item.id,
            name: item.perfumeName,
            brand: item.brandName,
            imageUrl: item.imageURL,
            rawMainAccords: item.parsedAccords,
            mainAccords: item.parsedAccords,
            topNotes: nil,
            middleNotes: nil,
            baseNotes: nil,
            concentration: nil,
            gender: nil,
            season: nil,
            situation: nil,
            longevity: nil,
            sillage: nil
        )

        collectionRepository.saveLikedPerfume(perfume)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.insert(item.id)
                self?.recommendationCollectionView.reloadData()
            }, onError: { [weak self] error in
                self?.presentLikeMutationError(error)
            })
            .disposed(by: disposeBag)
    }

    func deleteLike(id: String) {
        collectionRepository.deleteLikedPerfume(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.remove(id)
                self?.recommendationCollectionView.reloadData()
            }, onError: { [weak self] error in
                self?.presentLikeMutationError(error)
            })
            .disposed(by: disposeBag)
    }

    func presentLikeMutationError(_ error: Error) {
        if let limitError = error as? CollectionUsageLimitError {
            showAppToast(message: limitError.localizedDescription, bottomOffset: 84)
        } else {
            presentAlert(error.localizedDescription)
        }
    }

    var visibleRecommendations: [HomePerfumeItem] {
        Array(recommendations.prefix(5))
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleRecommendations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomePerfumeCardCell.reuseIdentifier,
            for: indexPath
        ) as? HomePerfumeCardCell else {
            return UICollectionViewCell()
        }

        let item = visibleRecommendations[indexPath.item]
        cell.configure(with: item, isLiked: likedPerfumeIDs.contains(item.id))
        cell.wishlistButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.likedPerfumeIDs.contains(item.id) {
                    self.deleteLike(id: item.id)
                } else {
                    self.saveLike(for: item)
                }
            })
            .disposed(by: cell.disposeBag)
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: Layout.cardWidth, height: Layout.cardHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: Layout.horizontalInset, bottom: 0, right: Layout.horizontalInset)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigateToPerfumeDetail(visibleRecommendations[indexPath.item].perfume)
    }
}

private final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}

private final class HomeGradientView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let beigeOverlayView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = UIColor(red: 0.96, green: 0.92, blue: 0.88, alpha: 1)
        gradientLayer.colors = [
            UIColor(red: 0.84, green: 0.49, blue: 0.58, alpha: 1).cgColor,
            UIColor(red: 0.95, green: 0.69, blue: 0.78, alpha: 1).cgColor,
            UIColor(red: 0.96, green: 0.92, blue: 0.88, alpha: 0.92).cgColor,
            UIColor(red: 0.96, green: 0.92, blue: 0.88, alpha: 1).cgColor
        ]
        gradientLayer.locations = [0.0, 0.52, 0.82, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.12, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.88, y: 1.0)
        layer.addSublayer(gradientLayer)

        beigeOverlayView.backgroundColor = UIColor(red: 0.96, green: 0.92, blue: 0.88, alpha: 0.22)
        addSubview(beigeOverlayView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        beigeOverlayView.frame = bounds
    }
}
