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

final class HomeViewController: UIViewController {

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let cardWidth: CGFloat = 132
        static let cardHeight: CGFloat = 226  // Figma Card/perfume_M: 132(이미지) + 94(텍스트+향계열)
        static let cardSpacing: CGFloat = 16
    }

    private enum Typography {
        static func hahmlet(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let preferredName: String
            switch weight {
            case .bold, .heavy, .black:
                preferredName = "Hahmlet-Bold"
            case .medium, .semibold:
                preferredName = "Hahmlet-Medium"
            default:
                preferredName = "Hahmlet"
            }

            return UIFont(name: preferredName, size: size)
                ?? UIFont(name: "Hahmlet", size: size)
                ?? .systemFont(ofSize: size, weight: weight)
        }

        static func pretendard(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let preferredName: String
            switch weight {
            case .semibold:
                // Pretendard-SemiBold 없으면 Bold로 fallback
                preferredName = "Pretendard-SemiBold"
            case .medium:
                preferredName = "Pretendard-Medium"
            case .bold, .heavy, .black:
                preferredName = "Pretendard-Bold"
            default:
                preferredName = "Pretendard-Regular"
            }

            return UIFont(name: preferredName, size: size)
                ?? UIFont(name: "Pretendard-Medium", size: size)
                ?? UIFont(name: "Pretendard", size: size)
                ?? .systemFont(ofSize: size, weight: weight)
        }
    }

    private let viewModel: HomeViewModel
    private let userTasteRepository: UserTasteRepositoryType
    private let collectionRepository: CollectionRepositoryType
    private let tastingRecordRepository: TastingRecordRepositoryType
    private let localTastingNoteRepository: LocalTastingNoteRepository
    private let disposeBag = DisposeBag()
    private let homeRefreshRelay = PublishRelay<Void>()
    private var recommendations: [HomePerfumeItem] = []
    private var popularRecommendations: [HomePerfumeItem] = []
    private var currentProfileItem: HomeViewModel.HomeProfileItem?
    private var currentBannerItem: HomeTasteBannerItem?
    private var likedPerfumeIDs = Set<String>()
    private var tastingNoteKeys = Set<String>()
    private var profileChangeObserver: NSObjectProtocol?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let topGradientView = HomeGradientView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(
            string: AppStrings.UIKitScreens.Home.title,
            attributes: [
                .font: Typography.hahmlet(size: 24, weight: .bold),
                .kern: 2
            ]
        )
        label.textColor = .label
        return label
    }()

    private let addPerfumeButton: UIButton = {
        let button = UIButton(type: .system)
button.setImage(UIImage(systemName: "plus"), for: .normal)
button.setPreferredSymbolConfiguration(
    UIImage.SymbolConfiguration(pointSize: 24, weight: .regular),
    forImageIn: .normal
)

        button.tintColor = .label
        button.accessibilityLabel = AppStrings.UIKitScreens.PerfumeDetail.addCollection
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
        label.font = Typography.hahmlet(size: 24, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let profileSummaryLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.pretendard(size: 13, weight: .medium)
        label.textColor = UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 1)
        label.numberOfLines = 2
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
        // Figma: Pretendard, 18, semibold, Color(0.13, 0.13, 0.13)
        label.font = Typography.pretendard(size: 18, weight: .semibold)
        label.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
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

    private let popularRecommendationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Home.popularRecommendTitle
        label.font = Typography.pretendard(size: 18, weight: .semibold)
        label.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        return label
    }()

    private let popularRecommendationCollectionView: UICollectionView = {
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
        view.backgroundColor = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
        view.layer.cornerRadius = 8
        view.layer.cornerCurve = .continuous
        // Figma: border 없음
        return view
    }()

    private let guideIconView: UIImageView = {
        let imageView = UIImageView()
        // Figma: 테두리 원형 물음표 → questionmark.circle (회색 단색)
        let sizeConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView.image = UIImage(systemName: "questionmark.circle", withConfiguration: sizeConfig)
        imageView.tintColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let guideLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.UIKitScreens.Home.guide
        label.font = UIFont(name: "Pretendard-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1)
        label.numberOfLines = 0
        return label
    }()

    init(
        viewModel: HomeViewModel,
        userTasteRepository: UserTasteRepositoryType,
        collectionRepository: CollectionRepositoryType,
        tastingRecordRepository: TastingRecordRepositoryType,
        localTastingNoteRepository: LocalTastingNoteRepository
    ) {
        self.viewModel = viewModel
        self.userTasteRepository = userTasteRepository
        self.collectionRepository = collectionRepository
        self.tastingRecordRepository = tastingRecordRepository
        self.localTastingNoteRepository = localTastingNoteRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let profileChangeObserver {
            NotificationCenter.default.removeObserver(profileChangeObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 상태바 영역까지 레이아웃 확장
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        setupUI()
        bind()
        observeProfileChange()
    }

    // contentInsetAdjustmentBehavior = .never 사용 시 탭바 safe area 수동 설정
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        scrollView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: view.safeAreaInsets.bottom,
            right: 0
        )
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 네비게이션 바 투명 처리 → 상태바 배경 투명화
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        loadLikedPerfumes()
        loadTastingNoteKeys()
    }
}

private extension HomeViewController {

    func setupUI() {
        // 최상단 bounce 영역: 그라데이션 베이스 크림 색상
        view.backgroundColor = .systemBackground
        // 그라데이션 영역(351pt) 아래는 흰색 배경
        contentView.backgroundColor = .systemBackground

        recommendationCollectionView.delegate = self
        recommendationCollectionView.dataSource = self
        recommendationCollectionView.register(
            HomePerfumeCardCell.self,
            forCellWithReuseIdentifier: HomePerfumeCardCell.reuseIdentifier
        )
        popularRecommendationCollectionView.delegate = self
        popularRecommendationCollectionView.dataSource = self
        popularRecommendationCollectionView.register(
            HomePerfumeCardCell.self,
            forCellWithReuseIdentifier: HomePerfumeCardCell.reuseIdentifier
        )

        view.addSubview(scrollView)
        scrollView.contentInsetAdjustmentBehavior = .never  // 상태바 영역까지 그라데이션 확장
        scrollView.backgroundColor = .clear  // view.backgroundColor(크림)가 상단 bounce 시 투과되도록
        scrollView.addSubview(contentView)
        contentView.addSubview(topGradientView)

        [
            titleLabel,
            addPerfumeButton,
            profileHeroCard,
            recommendationTitleLabel,
            recommendationCollectionView,
            popularRecommendationTitleLabel,
            popularRecommendationCollectionView,
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
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        // Figma 기준: 배경 그라데이션 W=390(풀너비), H=351 고정
        topGradientView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(351)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }

        addPerfumeButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(24)
        }

        profileHeroCard.snp.makeConstraints {
            // Figma: 킁킁 아래 최소 16pt 간격, 향 계열 태그는 그라데이션 하단에서 20pt 위
            $0.top.greaterThanOrEqualTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(topGradientView.snp.bottom).offset(-20)
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
            $0.top.equalTo(profileHeadlineLabel.snp.bottom).offset(8)
            $0.leading.equalTo(profileHeadlineLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        profileTagStack.snp.makeConstraints {
            $0.top.equalTo(profileSummaryLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
            $0.bottom.equalToSuperview()
        }

        // Figma: 그라데이션 영역 끝(351pt)에서 26pt 아래
        recommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(topGradientView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        recommendationCollectionView.snp.makeConstraints {
            $0.top.equalTo(recommendationTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.cardHeight)
        }

        popularRecommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(recommendationCollectionView.snp.bottom).offset(28)
            $0.leading.equalToSuperview().offset(16)
        }

        popularRecommendationCollectionView.snp.makeConstraints {
            $0.top.equalTo(popularRecommendationTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Layout.cardHeight)
        }

        guideContainerView.snp.makeConstraints {
            $0.top.equalTo(popularRecommendationCollectionView.snp.bottom).offset(34)  // Figma: 34pt gap
            $0.leading.trailing.equalToSuperview().inset(16)  // Figma: 16pt 좌우 여백 → 358pt 너비
            $0.bottom.equalToSuperview().inset(20)
        }

        guideIconView.snp.makeConstraints {
            // Figma: HStack alignment .center → centerY, leading 12pt, size 20×20
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        guideLabel.snp.makeConstraints {
            // Figma: padding vertical 16pt, HStack spacing 12pt, trailing inset 12pt
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.equalTo(guideIconView.snp.trailing).offset(14)  // Figma: 14pt
            $0.trailing.equalToSuperview().inset(12)
        }
    }

    @objc func profileCardTapped() {
        guard let item = currentProfileItem else { return }
        let profileVC = TasteProfileViewController(profileItem: item, userTasteRepository: userTasteRepository)
        navigationController?.pushViewController(profileVC, animated: true)
    }
}

private extension HomeViewController {

    func observeProfileChange() {
        profileChangeObserver = NotificationCenter.default.addObserver(
            forName: .tasteProfileDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.homeRefreshRelay.accept(())
            guard
                let title = notification.userInfo?["title"] as? String,
                let families = notification.userInfo?["families"] as? [String]
            else { return }
            // 배너 타이틀 즉시 갱신
            self.profileHeadlineLabel.text = title
            self.topGradientView.configure(title: title, fallbackFamilies: Array(families.prefix(2)))
        }
    }

    func bind() {
        let notificationRefresh = Observable.merge(
            NotificationCenter.default.rx.notification(.perfumeCollectionDidChange).map { _ in },
            NotificationCenter.default.rx.notification(.tastingNotesDidChange).map { _ in }
        )

        let homeRefresh = Observable.merge(
            homeRefreshRelay.asObservable(),
            notificationRefresh
        )
        .throttle(.milliseconds(500), scheduler: MainScheduler.instance)

        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            refresh: homeRefresh,
            perfumeRegisterTap: .never(),
            tastingNoteTap: .never(),
            reportTap: .never(),
            perfumeSelect: .never()
        )

        let output = viewModel.transform(input: input)

        bindBanner(output.banner)
        bindProfile(output.profile)
        bindRecommendations(output.recommendations)
        bindPopularRecommendations(output.popularRecommendations)
        bindRoute(output.route)
        bindAddPerfumeButton()
    }

    func bindBanner(_ banner: Driver<HomeTasteBannerItem>) {
        banner
            .drive(with: self) { owner, item in
                owner.currentBannerItem = item
                owner.profileHeadlineLabel.text = item.title
                owner.profileSummaryLabel.text = item.summary
                owner.updateProfileTags(with: owner.currentProfileItem?.profile, banner: item)

                if owner.currentProfileItem == nil, !item.familyText.isEmpty {
                    let families = item.familyText
                        .components(separatedBy: "·")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    owner.topGradientView.configure(title: item.title, fallbackFamilies: families)
                }
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
                owner.topGradientView.configure(
                    title: item.profile.displayTitle,
                    fallbackFamilies: Array(item.profile.displayFamilies.prefix(2))
                )
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

    func bindPopularRecommendations(_ recommendations: Driver<[HomePerfumeItem]>) {
        recommendations
            .drive(with: self) { owner, items in
                owner.popularRecommendations = items
                owner.popularRecommendationTitleLabel.isHidden = items.isEmpty
                owner.popularRecommendationCollectionView.isHidden = items.isEmpty
                owner.popularRecommendationCollectionView.reloadData()
            }
            .disposed(by: disposeBag)
    }

    func bindRoute(_ route: Signal<HomeRoute>) {
        route
            .emit(with: self) { owner, route in owner.handleRoute(route) }
            .disposed(by: disposeBag)
    }

    func bindAddPerfumeButton() {
        addPerfumeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let searchViewController = SearchSceneFactory.makeSearchViewController(
                    dependencyContainer: AppDependencyContainer.shared,
                    showsRecentOnAppear: true,
                    mode: .register
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
        dotView.layer.cornerRadius = 4

        let label = UILabel()
        label.text = text
        // Figma: Pretendard, 12, medium, Color(0.52, 0.52, 0.52)
        label.font = Typography.pretendard(size: 12, weight: .medium)
        label.textColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)

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
            $0.size.equalTo(CGSize(width: 8, height: 8))
        }

        stack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(5)
            $0.leading.trailing.equalToSuperview().inset(12)
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
        case "Water": return "워터"
        case "Aromatic": return "아로마틱"
        default: return family
        }
    }
}

private extension HomeViewController {

    func handleRoute(_ route: HomeRoute) {
        switch route {
        case .perfumeRegister:
            navigateToMyPage()
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

    func navigateToMyPage() {
        MainTabRouter.shared.select(.my)
    }
}

private extension HomeViewController {

    func loadLikedPerfumes() {
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.likedPerfumeIDs = Set(items.map(\.id))
                self?.reloadRecommendationCollections()
            })
            .disposed(by: disposeBag)
    }

    func loadTastingNoteKeys() {
        // 1단계: CoreData 로컬에서 즉시 반영 (동기) — Firestore 동기화 전에도 배지 표시
        if let localNotes = try? localTastingNoteRepository.loadNotes() {
            tastingNoteKeys = Set(localNotes.flatMap {
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: $0.perfumeName,
                    brandName: $0.brandName
                )
            })
            reloadRecommendationCollections()
        }

        // 2단계: Firestore에서 추가 병합 (비동기) — 다른 기기 기록까지 포함
        tastingRecordRepository.fetchTastingRecords()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] records in
                guard let self else { return }
                let remoteKeys = Set(records.flatMap {
                    PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: $0.perfumeName,
                        brandName: $0.brandName
                    )
                })
                self.tastingNoteKeys.formUnion(remoteKeys)
                self.reloadRecommendationCollections()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    func saveLike(for item: HomePerfumeItem) {
        let collectionID = Perfume.collectionDocumentID(from: item.id)
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
                self?.likedPerfumeIDs.insert(collectionID)
                self?.reloadRecommendationCollections()
                NotificationCenter.default.post(name: .perfumeCollectionDidChange, object: nil)
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
                self?.reloadRecommendationCollections()
                NotificationCenter.default.post(name: .perfumeCollectionDidChange, object: nil)
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

    var visiblePopularRecommendations: [HomePerfumeItem] {
        Array(popularRecommendations.prefix(5))
    }

    func visibleItems(for collectionView: UICollectionView) -> [HomePerfumeItem] {
        collectionView == popularRecommendationCollectionView
            ? visiblePopularRecommendations
            : visibleRecommendations
    }

    func reloadRecommendationCollections() {
        recommendationCollectionView.reloadData()
        popularRecommendationCollectionView.reloadData()
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleItems(for: collectionView).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomePerfumeCardCell.reuseIdentifier,
            for: indexPath
        ) as? HomePerfumeCardCell else {
            return UICollectionViewCell()
        }

        let item = visibleItems(for: collectionView)[indexPath.item]
        let collectionID = Perfume.collectionDocumentID(from: item.id)
        let hasTastingRecord = !tastingNoteKeys.isDisjoint(
            with: PerfumePresentationSupport.recordMatchingKeys(
                perfumeName: item.perfumeName,
                brandName: item.brandName
            )
        )
        cell.configure(
            with: item,
            isLiked: likedPerfumeIDs.contains(collectionID),
            hasTastingRecord: hasTastingRecord
        )
        cell.wishlistButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.likedPerfumeIDs.contains(collectionID) {
                    self.deleteLike(id: collectionID)
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
        navigateToPerfumeDetail(visibleItems(for: collectionView)[indexPath.item].perfume)
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

final class HomeGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    // Figma 기준 base 크림 색상: Color(red: 0.95, green: 0.91, blue: 0.87)
    private static let baseCream = UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = HomeGradientView.baseCream
        // Figma EllipticalGradient: center UnitPoint(x: 0.48, y: 0) → 상단 중앙에서 방사형
        gradientLayer.type = .radial
        gradientLayer.startPoint = CGPoint(x: 0.48, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(gradientLayer)
        applyDefaultGradient()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func configure(topFamilies: [String]) {
        let top1Color = topFamilies.first.map { ScentFamilyColor.color(for: $0) }
        let top2Color = topFamilies.dropFirst().first.map { ScentFamilyColor.color(for: $0) }

        let color20 = (top2Color ?? top1Color?.softened(amount: 0.25)
            ?? UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1))
            .softened(amount: 0.20)
        let color45 = (top1Color
            ?? UIColor(red: 0.66, green: 0.81, blue: 0.91, alpha: 1))
            .softened(amount: 0.30)

        gradientLayer.colors = [
            color20.cgColor,
            color45.cgColor,
            HomeGradientView.baseCream.cgColor
        ]
        gradientLayer.locations = [0.0, 0.45, 1.00]
    }

    func configure(title: String, fallbackFamilies: [String]) {
        if let preset = TasteProfileGradientIconView.profilePreset(forTitle: title) {
            configure(exactColors: preset.colors, locations: preset.locations)
            return
        }

        guard let palette = FragranceProfileText.profileColorPalette(forTitle: title) else {
            configure(topFamilies: fallbackFamilies)
            return
        }

        gradientLayer.colors = [
            UIColor(hex: palette.accentHex).cgColor,
            UIColor(hex: palette.primaryHex).cgColor,
            UIColor(hex: palette.baseHex).cgColor
        ]
        // location 0.0부터 시작: 중심에 고형색 원(blob) 없이 부드러운 방사형 그라데이션
        gradientLayer.locations = [0.0, NSNumber(value: palette.primaryLocation), 1.00]
    }

    func configure(exactColors colors: [UIColor], locations: [NSNumber]) {
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.locations = locations
    }

    // Figma EllipticalGradient 기본값:
    // Color(red: 0.95, green: 0.9, blue: 0.68) → Color(red: 0.66, green: 0.81, blue: 0.91) → cream
    private func applyDefaultGradient() {
        gradientLayer.colors = [
            UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1).cgColor,
            UIColor(red: 0.66, green: 0.81, blue: 0.91, alpha: 1).cgColor,
            HomeGradientView.baseCream.cgColor
        ]
        gradientLayer.locations = [0.0, 0.45, 1.00]
    }
}
