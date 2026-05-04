//
//  SearchViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//
// 킁킁(Sniff) - 검색 메인 ViewController
   

import UIKit
import SwiftUI
import SnapKit
import Then
import RxSwift
import RxCocoa
import Kingfisher

final class SearchViewController: UIViewController {

    private enum SearchStyle {
        static let neutral950 = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        static let neutral400 = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1)
        static let searchBackground = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
        static let clearButtonEditingBackground = UIColor.black.withAlphaComponent(0.5)
        static let clearButtonResultBackground = UIColor(red: 0.74, green: 0.74, blue: 0.74, alpha: 0.5)

        static func pretendard(size: CGFloat, weight: UIFont.Weight) -> UIFont {
            let preferredName: String
            switch weight {
            case .semibold:
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

        static func searchIconImage(color: UIColor = .black) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = UIScreen.main.scale

            return UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24), format: format).image { _ in
                let path = UIBezierPath()
                path.lineWidth = 3
                path.lineCapStyle = .round
                path.lineJoinStyle = .round

                color.setStroke()
                UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 13.5, height: 13.5)).stroke()
                path.move(to: CGPoint(x: 14.5, y: 14.5))
                path.addLine(to: CGPoint(x: 21, y: 21))
                path.stroke()
            }.withRenderingMode(.alwaysOriginal)
        }
    }

        // MARK: - Properties
    private let viewModel: SearchViewModel
    private let collectionRepository: CollectionRepositoryType
    private let tastingRecordRepository: TastingRecordRepositoryType
    private let localTastingNoteRepository: LocalTastingNoteRepository
    private let showsRecentOnAppear: Bool
    private let mode: PerfumeSearchMode
    private let disposeBag = DisposeBag()

    private let searchTextRelay = BehaviorRelay<String>(value: "")
    private let searchTriggerRelay = PublishRelay<String>()
    private let clearTriggerRelay = PublishRelay<Void>()
    private let recentSearchTapRelay = PublishRelay<String>()
    private let suggestionTapRelay = PublishRelay<SuggestionItem>()
    private let deleteRecentSearchRelay = PublishRelay<String>()
    private let clearAllRecentSearchesRelay = PublishRelay<Void>()
    private let filterChangedRelay = PublishRelay<SearchFilter>()
    private let sortChangedRelay = PublishRelay<SortOption>()

    private var currentState: SearchState
    private var currentFilter: SearchFilter = SearchFilter()
    private var currentSort: SortOption = .recommended
    private var brandResults: [Perfume] = []
    private var allPerfumeResults: [Perfume] = []
    private var filteredPerfumeResults: [Perfume] = []

        // 테이블뷰 로컬 캐시 — ViewModel output을 받아 저장
    private var recentSearches: [RecentSearch] = []
    private var suggestions: [SuggestionItem] = []
    private var keyboardInset: CGFloat = 0
    private var likedPerfumeIDs = Set<String>()
    private var ownedPerfumeIDs = Set<String>()
    private var tastingNoteKeys = Set<String>()
    private var hasHandledRecentOnAppear = false
    private var isRegisteringCollection = false
    private var pendingRegisterSuggestion: (name: String, brand: String)?
    private weak var presentedTastingFormController: UIViewController?

    // MARK: - 자동저장 상태
    /// ViewModel에서 받아온 자동저장 활성화 여부 로컬 캐시
    private var isAutoSaveEnabled = true
    /// 키보드가 현재 화면에 올라와 있는지 여부
    private var isKeyboardVisible = false
    private var pendingAutoSaveEnabled = false

        // MARK: - UI Components

    private let backButton = UIButton(type: .system).then {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        $0.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        $0.tintColor = .label
        $0.isHidden = true
        $0.contentHorizontalAlignment = .center
    }

        // 상단 검색바
    private let searchBar = UISearchBar().then {
        $0.placeholder = AppStrings.UIKitScreens.Search.placeholder
        $0.searchBarStyle = .minimal
        $0.returnKeyType = .search
        $0.searchTextField.font = SearchStyle.pretendard(size: 16, weight: .medium)
        $0.searchTextField.clearButtonMode = .never
        $0.searchTextField.attributedPlaceholder = NSAttributedString(
            string: AppStrings.UIKitScreens.Search.placeholder,
            attributes: [
                .font: SearchStyle.pretendard(size: 16, weight: .medium),
                .foregroundColor: SearchStyle.neutral400
            ]
        )
    }
    private let searchSubmitButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = SearchStyle.searchIconImage(color: .black)
        config.baseForegroundColor = .black
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    private let searchClearButton: UIButton = {
        // X 버튼: Figma 스펙 — 20×20 pill, black 50% 배경, 흰색 xmark 아이콘
        let btn = UIButton(type: .custom)
        btn.backgroundColor = SearchStyle.clearButtonEditingBackground
        btn.layer.cornerRadius = 10
        btn.layer.cornerCurve = .continuous
        btn.clipsToBounds = true
        let xImage = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        )
        btn.setImage(xImage, for: .normal)
        btn.tintColor = .white
        return btn
    }()
    private let landingGuideLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        $0.text = AppStrings.UIKitScreens.Search.landingGuideMessage
        $0.isHidden = true
    }

        // 결과 카운트 + 필터 버튼 + 정렬 버튼
    private let resultHeaderView = UIView().then {
        $0.isHidden = true
    }

private let resultCountLabel = UILabel().then {
    $0.textColor = .label
}

    private let resultDividerView = UIView().then {
        $0.backgroundColor = UIColor(hex: "#E2E0DD")
    }

private let filterButton = UIButton(type: .system).then {
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
    $0.setImage(UIImage(systemName: "slider.horizontal.3", withConfiguration: symbolConfig), for: .normal)
    $0.tintColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
}

// 향수N개 | 필터 사이 구분선
private let countSeparatorView = UIView().then {
    $0.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1)
}

private let sortButton = UIButton(type: .system).then {
    let neutral800 = UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1)
    var config = UIButton.Configuration.plain()
    config.imagePlacement = .trailing
    config.imagePadding = 4
    config.image = UIImage(systemName: "chevron.down")
    config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
    config.baseForegroundColor = neutral800
    config.contentInsets = .zero
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
        var a = attrs
        a.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        a.foregroundColor = neutral800
        return a
    }
    $0.configuration = config
    $0.setTitle(AppStrings.UIKitScreens.Search.sortRecommended, for: .normal)
}

        // 브랜드 섹션 (결과 화면)
   private let brandSectionLabel = UILabel().then {
    $0.isHidden = true
}

    private let brandEmptyLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        $0.isHidden = true
    }

        // 메인 테이블뷰 — 초기/연관 검색어
    private lazy var tableView = UITableView().then {
        $0.register(RecentSearchCell.self, forCellReuseIdentifier: RecentSearchCell.identifier)
        $0.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.identifier)
        $0.register(SearchMessageCell.self, forCellReuseIdentifier: SearchMessageCell.identifier)
        $0.register(PerfumeSearchResultCell.self, forCellReuseIdentifier: PerfumeSearchResultCell.identifier)
        $0.separatorStyle = .none
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 68
        $0.backgroundColor = .systemBackground
        $0.keyboardDismissMode = .onDrag
    }

        // 브랜드 가로 스크롤 (결과 화면)
    private lazy var brandTableView = UITableView().then {
        $0.register(BrandResultCell.self, forCellReuseIdentifier: BrandResultCell.identifier)
        $0.separatorStyle = .none
        $0.rowHeight = 84
        $0.isHidden = true
        $0.isScrollEnabled = false
        $0.keyboardDismissMode = .onDrag
        $0.backgroundColor = .systemBackground
    }

        // 향수 그리드
    private lazy var perfumeCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 16
        let itemWidth = (UIScreen.main.bounds.width - 48) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 86)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 18, left: 24, bottom: 110, right: 24)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(PerfumeGridCell.self, forCellWithReuseIdentifier: PerfumeGridCell.identifier)
        cv.backgroundColor = .systemBackground
        cv.isHidden = true
        cv.keyboardDismissMode = .onDrag
        return cv
    }()

        // 빈 상태 뷰
    private let emptyView = SearchEmptyView().then {
        $0.isHidden = true
    }

        // 최근 검색어 헤더 (초기 상태)
    private let recentHeaderView = UIView()
    private let recentTitleLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Search.recentTitle
        $0.font = SearchStyle.pretendard(size: 18, weight: .semibold)
        $0.textColor = SearchStyle.neutral950
    }

    // MARK: - 연관 검색어 헤더

    /// 타이핑 중(suggesting) 상태에서 테이블뷰 상단에 표시되는 "연관 검색어" 헤더뷰
    private let suggestionHeaderView = UIView()
    private let suggestionTitleLabel = UILabel().then {
        $0.text = "연관 검색어"
        $0.font = SearchStyle.pretendard(size: 18, weight: .semibold)
        $0.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1) // Atomic/Neutral/950
    }
    private let clearAllButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.clearAll, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = SearchStyle.pretendard(size: 14, weight: .medium)
        $0.contentHorizontalAlignment = .left
        $0.isHidden = true
    }
    private let recentFooterView = UIView()
    // MARK: - 자동저장 목록 푸터

    /// 최근 검색어 화면(initial state) 목록 바로 아래에 표시되는 자동저장 설정 바
    private let autoSaveBarView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1)
    }
    /// 바 상단 얇은 구분선
    private let autoSaveBarTopLine = UIView().then {
        $0.backgroundColor = UIColor(red: 0.88, green: 0.86, blue: 0.83, alpha: 1)
    }
    /// "자동저장 켜기" / "자동저장 끄기" 토글 버튼
    private let autoSaveToggleButton = UIButton(type: .system).then {
        $0.setTitleColor(UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
    }
    /// 최근 검색어 모두 지우기 버튼
    private let autoSaveClearAllButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.clearAll, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
    }
    /// 닫기 버튼 — 키보드 내리기
    private let autoSaveCloseButton = UIButton(type: .system).then {
        $0.setTitle("닫기", for: .normal)
        $0.setTitleColor(UIColor(red: 0.39, green: 0.39, blue: 0.39, alpha: 1), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
    }

    private let autoSaveAlertOverlayView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        $0.isHidden = true
    }
    private let autoSaveAlertCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 24
        $0.layer.cornerCurve = .continuous
        $0.clipsToBounds = true
    }
    private let autoSaveAlertMessageLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 0
        $0.textAlignment = .left
    }
    private let autoSaveAlertCancelButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.cancel, for: .normal)
        $0.setTitleColor(.label, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.backgroundColor = UIColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1)
        $0.layer.cornerRadius = 18
        $0.layer.cornerCurve = .continuous
    }
    private let autoSaveAlertConfirmButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.confirm, for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.backgroundColor = UIColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 1)
        $0.layer.cornerRadius = 18
        $0.layer.cornerCurve = .continuous
    }

    private var resultHeaderTopToGuideConstraint: Constraint?
    private var resultHeaderTopToBrandConstraint: Constraint?
    private var resultHeaderTopToBrandEmptyConstraint: Constraint?
    private var searchBarLeadingToBackConstraint: Constraint?
    private var searchBarLeadingToSuperviewConstraint: Constraint?

        // MARK: - Init

    init(
        viewModel: SearchViewModel,
        collectionRepository: CollectionRepositoryType,
        tastingRecordRepository: TastingRecordRepositoryType,
        localTastingNoteRepository: LocalTastingNoteRepository,
        showsRecentOnAppear: Bool = false,
        mode: PerfumeSearchMode = .browse
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
        self.tastingRecordRepository = tastingRecordRepository
        self.localTastingNoteRepository = localTastingNoteRepository
        self.showsRecentOnAppear = showsRecentOnAppear
        self.mode = mode
        self.currentState = showsRecentOnAppear && mode != .register ? .initial : .landing
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupCollectionView()
        bindViewModel()
        bindKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        if case .result = currentState {
            backButton.isHidden = false
        } else if mode == .register {
            backButton.isHidden = false
        } else if case .initial = currentState {
            backButton.isHidden = false
        } else if case .suggesting = currentState {
            backButton.isHidden = false
        } else {
            backButton.isHidden = (navigationController?.viewControllers.count ?? 0) <= 1
        }
        updateSearchBarLeadingConstraint()
        loadLikedPerfumes()
        loadCollectedPerfumes()
        loadTastingNoteKeys()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard showsRecentOnAppear, !hasHandledRecentOnAppear else { return }
        hasHandledRecentOnAppear = true
        searchBar.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if tableView.tableFooterView === autoSaveBarView,
           autoSaveBarView.frame.width != tableView.bounds.width {
            configureAutoSaveFooter()
        }
    }
}

private extension SearchViewController {

    // MARK: - UI Setup

    func setupUI() {
        view.backgroundColor = .systemBackground

        configureSearchBarAppearance()
        setupRecentHeader()
        setupSuggestionHeader()
        addSubviews()
        makeConstraints()
        updateSearchBarLeadingConstraint()
        resultHeaderTopToBrandConstraint?.deactivate()
        resultHeaderTopToBrandEmptyConstraint?.deactivate()

        // 자동저장 토글 버튼 초기 타이틀 설정
        updateAutoSaveToggleTitle()
        updateAutoSaveBarItems()
    }

    func configureSearchBarAppearance() {
        // UISearchBar 자체 배경 완전 제거 → pill(searchTextField)만 노출
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.isTranslucent = true
        searchBar.setImage(UIImage(), for: .search, state: .normal)
        searchBar.searchTextField.backgroundColor = SearchStyle.searchBackground
        // 와이어프레임처럼 낮은 pill 형태
        searchBar.searchTextField.layer.cornerRadius = 20
        searchBar.searchTextField.layer.cornerCurve = .continuous
        searchBar.searchTextField.clipsToBounds = true
        searchBar.searchTextField.textColor = SearchStyle.neutral950
        searchBar.searchTextField.borderStyle = .none
        searchBar.searchTextField.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }

        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: mode == .register
                ? AppStrings.UIKitScreens.Search.registerPlaceholder
                : AppStrings.UIKitScreens.Search.placeholder,
            attributes: [
                .font: SearchStyle.pretendard(size: 16, weight: .medium),
                .foregroundColor: SearchStyle.neutral400
            ]
        )
        searchBar.searchTextField.textAlignment = .left
        // UISearchTextField 자체 기본 여백 약 8pt를 감안해 실제 텍스트 시작점을 16pt에 맞춘다.
        searchBar.searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 1))
        searchBar.searchTextField.leftViewMode = .always
        searchBar.searchTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 1))
        searchBar.searchTextField.rightViewMode = .always
        installSearchBarAccessoryButtonsIfNeeded()
        updateSearchBarAccessory(for: searchBar.text ?? "")
    }

    func updateSearchBarAccessory(for text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        searchSubmitButton.isHidden = !trimmedText.isEmpty
        searchClearButton.isHidden = trimmedText.isEmpty
        updateSearchClearButtonAppearance()
    }

    func updateSearchClearButtonAppearance() {
        if case .result = currentState {
            searchClearButton.backgroundColor = SearchStyle.clearButtonResultBackground
        } else {
            searchClearButton.backgroundColor = SearchStyle.clearButtonEditingBackground
        }
    }

    func installSearchBarAccessoryButtonsIfNeeded() {
        guard searchSubmitButton.superview == nil else { return }

        // 돋보기 버튼: Figma icon/search 24×24, pill 오른쪽 끝에서 16pt 안쪽
        searchBar.searchTextField.addSubview(searchSubmitButton)
        searchSubmitButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        // X 버튼: 20×20 pill, pill 오른쪽 끝에서 16pt 안쪽
        searchBar.searchTextField.addSubview(searchClearButton)
        searchClearButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
    }

    func setupRecentHeader() {
        recentHeaderView.addSubview(recentTitleLabel)
        recentTitleLabel.frame = CGRect(x: 16, y: 14, width: 220, height: 24)
        recentTitleLabel.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        recentHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 56)

        recentFooterView.addSubview(clearAllButton)
        clearAllButton.frame = CGRect(x: 16, y: 10, width: 140, height: 32)
        clearAllButton.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        recentFooterView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 52)
    }

    /// 연관 검색어 헤더뷰 초기 설정
    func setupSuggestionHeader() {
        suggestionHeaderView.addSubview(suggestionTitleLabel)
        // 검색바 하단 ~ 텍스트 상단 전체 간격 14pt (tableView offset 8pt + header top 6pt)
        suggestionTitleLabel.frame = CGRect(x: 16, y: 9.5, width: 220, height: 28)
        suggestionTitleLabel.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        suggestionHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 43.5)
    }

    func addSubviews() {
        [backButton, searchBar, resultHeaderView,
         landingGuideLabel,
         brandSectionLabel, brandEmptyLabel, brandTableView,
         tableView, perfumeCollectionView, emptyView,
         autoSaveAlertOverlayView].forEach {
            view.addSubview($0)
        }

        [resultCountLabel, countSeparatorView, filterButton, sortButton].forEach {
            resultHeaderView.addSubview($0)
        }

        // 자동저장 바 서브뷰
        [autoSaveBarTopLine, autoSaveToggleButton, autoSaveClearAllButton, autoSaveCloseButton].forEach {
            autoSaveBarView.addSubview($0)
        }

        autoSaveAlertOverlayView.addSubview(autoSaveAlertCardView)
        [autoSaveAlertMessageLabel, autoSaveAlertCancelButton, autoSaveAlertConfirmButton].forEach {
            autoSaveAlertCardView.addSubview($0)
        }
    }

    func makeConstraints() {
        backButton.snp.makeConstraints {
            $0.centerY.equalTo(searchBar.snp.centerY)
            $0.leading.equalToSuperview().offset(16)
            // 와이어프레임: 뒤로가기 버튼 폭 약 20pt (검색바 41pt 기준 상하 10.5pt 여백)
            $0.width.equalTo(20)
            $0.height.equalTo(24)
        }

        searchBar.snp.makeConstraints {
            // 글씨 위아래 4pt 여백이 보이도록 pill 높이를 40pt로 고정
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            searchBarLeadingToBackConstraint = $0.leading.equalTo(backButton.snp.trailing).offset(20).constraint
            searchBarLeadingToSuperviewConstraint = $0.leading.equalToSuperview().offset(16).constraint
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        landingGuideLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        resultHeaderView.snp.makeConstraints {
            resultHeaderTopToGuideConstraint = $0.top.equalTo(landingGuideLabel.snp.bottom).offset(8).constraint
            resultHeaderTopToBrandConstraint = $0.top.equalTo(brandTableView.snp.bottom).offset(34).constraint
            resultHeaderTopToBrandEmptyConstraint = $0.top.equalTo(brandEmptyLabel.snp.bottom).offset(24).constraint
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }
      resultCountLabel.snp.makeConstraints {
    $0.leading.equalToSuperview().offset(24)
    $0.centerY.equalToSuperview()
}

countSeparatorView.snp.makeConstraints {
    $0.leading.equalTo(resultCountLabel.snp.trailing).offset(12)
    $0.centerY.equalToSuperview()
    $0.width.equalTo(2)
    $0.height.equalTo(20)
}

filterButton.snp.makeConstraints {
    $0.leading.equalTo(countSeparatorView.snp.trailing).offset(8)
    $0.centerY.equalToSuperview()
    $0.size.equalTo(24)
    $0.trailing.lessThanOrEqualTo(sortButton.snp.leading).offset(-8)
}

sortButton.snp.makeConstraints {
    $0.trailing.equalToSuperview().offset(-24)
    $0.centerY.equalToSuperview()
}

        brandSectionLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(26)
            $0.leading.equalToSuperview().offset(24)
        }

        brandTableView.snp.makeConstraints {
            $0.top.equalTo(brandSectionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(0)
        }

        brandEmptyLabel.snp.makeConstraints {
            $0.top.equalTo(brandSectionLabel.snp.bottom).offset(28)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        perfumeCollectionView.snp.makeConstraints {
            $0.top.equalTo(resultHeaderView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyView.snp.makeConstraints {
            $0.top.equalTo(resultHeaderView.snp.bottom).offset(72)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        searchBarLeadingToBackConstraint?.deactivate()
        resultHeaderTopToBrandConstraint?.deactivate()
        resultHeaderTopToBrandEmptyConstraint?.deactivate()

        // MARK: 자동저장 바 레이아웃
        autoSaveBarTopLine.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        autoSaveToggleButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        autoSaveClearAllButton.snp.makeConstraints {
            $0.leading.equalTo(autoSaveToggleButton.snp.trailing).offset(18)
            $0.centerY.equalToSuperview()
        }

        autoSaveCloseButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        autoSaveAlertOverlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        autoSaveAlertCardView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(18)
            $0.leading.trailing.equalToSuperview().inset(44)
        }

        autoSaveAlertMessageLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(26)
            $0.leading.trailing.equalToSuperview().inset(28)
        }

        autoSaveAlertCancelButton.snp.makeConstraints {
            $0.top.equalTo(autoSaveAlertMessageLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(18)
            $0.bottom.equalToSuperview().offset(-18)
            $0.height.equalTo(52)
        }

        autoSaveAlertConfirmButton.snp.makeConstraints {
            $0.top.bottom.width.equalTo(autoSaveAlertCancelButton)
            $0.leading.equalTo(autoSaveAlertCancelButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-18)
        }
    }
}

private extension SearchViewController {

    // MARK: - Table/Collection Setup

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        brandTableView.delegate = self
        brandTableView.dataSource = self

        tableView.tableHeaderView = recentHeaderView
        recentHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 56)
        recentFooterView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 52)
        autoSaveBarView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
    }

    func setupCollectionView() {
        perfumeCollectionView.delegate = self
        perfumeCollectionView.dataSource = self
    }
}

private extension SearchViewController {

    // MARK: - Bind

    func bindViewModel() {
        let input = SearchViewModel.Input(
            beginEditing: searchBar.rx.textDidBeginEditing.asObservable(),
            searchText: searchTextRelay.asObservable(),
            searchTrigger: searchTriggerRelay.asObservable(),
            clearTrigger: clearTriggerRelay.asObservable(),
            recentSearchTap: recentSearchTapRelay.asObservable(),
            suggestionTap: suggestionTapRelay.asObservable(),
            deleteRecentSearch: deleteRecentSearchRelay.asObservable(),
            clearAllRecentSearches: clearAllRecentSearchesRelay.asObservable(),
            filterChanged: filterChangedRelay.asObservable(),
            sortChanged: sortChangedRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        bindState(output.state)
        bindRecentSearches(output.recentSearches)
        bindSuggestions(output.suggestions)
        bindBrandResults(output.brandResults)
        bindPerfumeResults(output.perfumeResults)
        bindFilteredPerfumeResults(output.filteredPerfumeResults)
        bindResultCount(output.resultCount)
        bindActiveFilter(output.activeFilter)
        bindCurrentSort(output.currentSort)
        bindSearchBar()
        bindActions()
        bindAutoSave()
    }

    func bindState(_ state: Observable<SearchState>) {
        state
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.currentState = state
                self?.updateLayout(for: state)
            })
            .disposed(by: disposeBag)
    }

    func bindRecentSearches(_ recentSearches: Observable<[RecentSearch]>) {
        recentSearches
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] searches in
                guard let self else { return }
                self.recentSearches = searches
                self.updateAutoSaveBarItems()
                if case .initial = self.currentState {
                    self.updateRecentTableChrome()
                    self.reloadTableView()
                }
            })
            .disposed(by: disposeBag)
    }

    func bindSuggestions(_ suggestions: Observable<[SuggestionItem]>) {
        suggestions
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] items in
                guard let self else { return }
                self.suggestions = self.mode == .register
                    ? self.registrationSuggestionItems(from: items)
                    : items
                if case .suggesting = self.currentState {
                    self.reloadTableView()
                }
            })
            .disposed(by: disposeBag)
    }

    func bindBrandResults(_ brandResults: Observable<[Perfume]>) {
        brandResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] brands in
                guard let self else { return }
                self.brandResults = brands
                self.brandSectionLabel.attributedText = self.makeCountAttributed(AppStrings.UIKitScreens.Search.brandCount(brands.count))
                self.brandTableView.snp.updateConstraints {
                    $0.height.equalTo(brands.isEmpty ? 0 : min(brands.count, 1) * 84)
                }
                self.brandTableView.reloadData()
                self.updateResultVisibility()
            })
            .disposed(by: disposeBag)
    }

    func bindPerfumeResults(_ perfumeResults: Observable<[Perfume]>) {
        perfumeResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfumes in
                self?.allPerfumeResults = perfumes
            })
            .disposed(by: disposeBag)
    }

    func bindFilteredPerfumeResults(_ filteredPerfumeResults: Observable<[Perfume]>) {
        filteredPerfumeResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfumes in
                guard let self else { return }
                self.filteredPerfumeResults = self.mode == .register
                    ? self.registrationPerfumeNameResults(from: perfumes)
                    : perfumes
                self.reloadPerfumeResults()
                self.updateResultVisibility()
                self.openPendingRegisterSuggestionIfPossible()
            })
            .disposed(by: disposeBag)
    }

    func bindResultCount(_ resultCount: Observable<Int>) {
        resultCount
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.resultCountLabel.attributedText = self?.makeCountAttributed(AppStrings.UIKitScreens.Search.perfumeCount(count))
            })
            .disposed(by: disposeBag)
    }

    func bindActiveFilter(_ activeFilter: Observable<SearchFilter>) {
        activeFilter
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                guard let self else { return }
                self.currentFilter = filter
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                let image = UIImage(systemName: "slider.horizontal.3", withConfiguration: symbolConfig)
                self.filterButton.setTitle(nil, for: .normal)
                self.filterButton.setImage(image, for: .normal)
                self.filterButton.tintColor = filter.isEmpty
                    ? UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
                    : .black
            })
            .disposed(by: disposeBag)
    }

    func bindCurrentSort(_ currentSort: Observable<SortOption>) {
        currentSort
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] sort in
                self?.currentSort = sort
                self?.sortButton.setTitle(sort.displayName, for: .normal)
            })
            .disposed(by: disposeBag)
    }

    func bindSearchBar() {
        searchBar.rx.text.orEmpty
            .do(onNext: { [weak self] text in
                self?.updateSearchBarAccessory(for: text)
            })
            .bind(to: searchTextRelay)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .withLatestFrom(searchTextRelay)
            .subscribe(onNext: { [weak self] text in
                self?.submitSearchQuery(text)
            })
            .disposed(by: disposeBag)

        searchSubmitButton.rx.tap
            .withLatestFrom(searchTextRelay)
            .subscribe(onNext: { [weak self] text in
                self?.submitSearchQuery(text)
            })
            .disposed(by: disposeBag)

        searchClearButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.searchBar.text = nil
                self.searchTextRelay.accept("")
                self.updateSearchBarAccessory(for: "")
                self.pendingRegisterSuggestion = nil
                self.clearTriggerRelay.accept(())
                self.searchBar.becomeFirstResponder()
            })
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.pendingRegisterSuggestion = nil
                self.currentState = .initial
                self.updateLayout(for: .initial)
            })
            .disposed(by: disposeBag)

        searchBar.rx.cancelButtonClicked
            .subscribe(onNext: { [weak self] in
                self?.pendingRegisterSuggestion = nil
                self?.clearTriggerRelay.accept(())
            })
            .disposed(by: disposeBag)
    }

    func bindActions() {
        filterButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentFilterSheet()
            })
            .disposed(by: disposeBag)

            // 정렬 버튼
        sortButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentSortActionSheet()
            })
            .disposed(by: disposeBag)

            // 모두 지우기
        clearAllButton.rx.tap
            .bind(to: clearAllRecentSearchesRelay)
            .disposed(by: disposeBag)

        backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if (self.navigationController?.viewControllers.count ?? 0) > 1 {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.searchBar.text = nil
                    self.searchTextRelay.accept("")
                    self.updateSearchBarAccessory(for: "")
                    self.clearTriggerRelay.accept(())
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - 자동저장 바인딩

    func bindAutoSave() {
        // ViewModel의 autoSaveEnabled 구독 → 로컬 상태 + UI 업데이트
        viewModel.autoSaveEnabled
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] enabled in
                guard let self else { return }
                self.isAutoSaveEnabled = enabled
                self.updateAutoSaveToggleTitle()
                self.updateAutoSaveBarItems()
                // initial 상태일 때 테이블 즉시 갱신
                if case .initial = self.currentState {
                    self.updateRecentTableChrome()
                    self.reloadTableView()
                }
            })
            .disposed(by: disposeBag)

        // "자동저장 켜기/끄기" 버튼
        autoSaveToggleButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.showAutoSaveConfirmAlert(enabling: !self.isAutoSaveEnabled)
            })
            .disposed(by: disposeBag)

        autoSaveClearAllButton.rx.tap
            .bind(to: clearAllRecentSearchesRelay)
            .disposed(by: disposeBag)

        // "닫기" 버튼 — 키보드 내리기
        autoSaveCloseButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.closeSearchOverlay()
            })
            .disposed(by: disposeBag)

        autoSaveAlertCancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.hideAutoSaveConfirmAlert()
            })
            .disposed(by: disposeBag)

        autoSaveAlertConfirmButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.hideAutoSaveConfirmAlert()
                self.viewModel.setAutoSaveEnabled(self.pendingAutoSaveEnabled)
            })
            .disposed(by: disposeBag)

    }

    /// 자동저장 활성화 여부에 따라 토글 버튼 타이틀 변경
    func updateAutoSaveToggleTitle() {
        let title = isAutoSaveEnabled ? "자동저장 끄기" : "자동저장 켜기"
        autoSaveToggleButton.setTitle(title, for: .normal)
    }

    func updateAutoSaveBarItems() {
        autoSaveClearAllButton.isHidden = !isAutoSaveEnabled || recentSearches.isEmpty
    }

    func showAutoSaveConfirmAlert(enabling: Bool) {
        pendingAutoSaveEnabled = enabling
        autoSaveAlertMessageLabel.text = enabling
            ? "최근검색어 저장 기능을\n사용하시겠습니까?"
            : "최근검색어 저장 기능을\n사용 중지하시겠습니까?"
        autoSaveAlertOverlayView.isHidden = false
        autoSaveAlertOverlayView.alpha = 0
        autoSaveAlertCardView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.autoSaveAlertOverlayView.alpha = 1
            self.autoSaveAlertCardView.transform = .identity
        }
    }

    func hideAutoSaveConfirmAlert() {
        UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseIn, animations: {
            self.autoSaveAlertOverlayView.alpha = 0
        }, completion: { _ in
            self.autoSaveAlertOverlayView.isHidden = true
        })
    }

    func closeSearchOverlay() {
        searchBar.resignFirstResponder()
        if (navigationController?.viewControllers.count ?? 0) > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            searchBar.text = nil
            searchTextRelay.accept("")
            updateSearchBarAccessory(for: "")
            clearTriggerRelay.accept(())
        }
    }
}

private extension SearchViewController {

    // MARK: - Layout

    func updateLayout(for state: SearchState) {
        switch state {
        case .landing:
            showLandingLayout()
        case .initial:
            showInitialLayout()
        case .suggesting:
            showSuggestingLayout()
        case .result:
            showResultLayout()
        }
        updateSearchBarAccessory(for: searchBar.text ?? "")
    }

    func showInitialLayout() {
        if mode == .register {
            showLandingLayout()
            return
        }
        tableView.isHidden = false
        resultHeaderView.isHidden = true
        landingGuideLabel.isHidden = true
        brandSectionLabel.isHidden = true
        brandEmptyLabel.isHidden = true
        brandTableView.isHidden = true
        perfumeCollectionView.isHidden = true
        emptyView.isHidden = true
        backButton.isHidden = false
        updateSearchBarLeadingConstraint()
        searchBar.showsCancelButton = false
        updateRecentTableChrome()
        reloadTableView()
        applyKeyboardInset()
    }

    func showSuggestingLayout() {
        tableView.isHidden = false
        resultHeaderView.isHidden = true
        landingGuideLabel.isHidden = true
        brandSectionLabel.isHidden = true
        brandEmptyLabel.isHidden = true
        brandTableView.isHidden = true
        perfumeCollectionView.isHidden = true
        emptyView.isHidden = true
        backButton.isHidden = false
        updateSearchBarLeadingConstraint()
        searchBar.showsCancelButton = false
        // "연관 검색어" 헤더 표시 — 너비를 현재 tableView 폭에 맞춰 갱신
        suggestionHeaderView.frame = CGRect(
            x: 0, y: 0,
            width: tableView.bounds.width,
            height: 43.5
        )
        tableView.tableHeaderView = suggestionHeaderView
        tableView.tableFooterView = nil
        applyKeyboardInset()
        reloadTableView()
    }

    func showResultLayout() {
        tableView.isHidden = true
        resultHeaderView.isHidden = false
        landingGuideLabel.isHidden = true
        backButton.isHidden = false
        updateSearchBarLeadingConstraint()
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        tableView.tableFooterView = nil
        applyKeyboardInset()
        updateResultVisibility()
    }

    func showLandingLayout() {
        if mode == .register {
            showRegisterEmptyLayout()
            return
        }

        tableView.isHidden = true
        resultHeaderView.isHidden = false
        landingGuideLabel.isHidden = true
        brandSectionLabel.isHidden = false
        brandTableView.isHidden = true
        perfumeCollectionView.isHidden = true
        emptyView.isHidden = false
        brandEmptyLabel.isHidden = false
        backButton.isHidden = (navigationController?.viewControllers.count ?? 0) <= 1
        updateSearchBarLeadingConstraint()
        searchBar.showsCancelButton = false
        brandSectionLabel.attributedText = makeCountAttributed(AppStrings.UIKitScreens.Search.brandCount(0))
        brandEmptyLabel.text = AppStrings.UIKitScreens.Search.landingBrandMessage
        resultCountLabel.attributedText = makeCountAttributed(AppStrings.UIKitScreens.Search.perfumeCount(0))
        brandTableView.snp.updateConstraints { $0.height.equalTo(0) }
        emptyView.configureLanding()
        resultHeaderTopToBrandConstraint?.deactivate()
        resultHeaderTopToGuideConstraint?.deactivate()
        resultHeaderTopToBrandEmptyConstraint?.activate()
        tableView.tableFooterView = nil
        applyKeyboardInset()
    }

    func showRegisterEmptyLayout() {
        tableView.isHidden = true
        resultHeaderView.isHidden = true
        landingGuideLabel.isHidden = true
        brandSectionLabel.isHidden = true
        brandTableView.isHidden = true
        brandEmptyLabel.isHidden = true
        perfumeCollectionView.isHidden = true
        emptyView.isHidden = false
        backButton.isHidden = (navigationController?.viewControllers.count ?? 0) <= 1
        updateSearchBarLeadingConstraint()
        searchBar.showsCancelButton = false
        tableView.tableHeaderView = nil
        tableView.tableFooterView = nil
        emptyView.configureLanding()
        applyKeyboardInset()
    }

    func reloadTableView() {
        tableView.reloadData()
    }

    func updateRecentTableChrome() {
        recentTitleLabel.isHidden = false
        recentHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56)
        tableView.tableHeaderView = recentHeaderView
        clearAllButton.isHidden = true
        configureAutoSaveFooter()
    }

    func configureRecentFooter() {
        recentFooterView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 52)
        clearAllButton.frame = CGRect(x: 16, y: 10, width: 140, height: 32)
        if !recentSearches.isEmpty {
            tableView.tableFooterView = recentFooterView
        }
    }

    func configureAutoSaveFooter() {
        autoSaveBarView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
        updateAutoSaveBarItems()
        tableView.tableFooterView = autoSaveBarView
    }

    func reloadPerfumeResults() {
        if mode == .register {
            tableView.reloadData()
        } else {
            perfumeCollectionView.reloadData()
        }
    }

    func submitSearchQuery(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            searchBar.becomeFirstResponder()
            return
        }

        guard mode != .register || hasRegistrationPerfumeNameCandidate(for: trimmedText) else {
            showAppToast(message: "향수명으로 검색해 주세요")
            searchBar.becomeFirstResponder()
            return
        }

        pendingRegisterSuggestion = nil
        searchTriggerRelay.accept(trimmedText)
    }

    func hasRegistrationPerfumeNameCandidate(for query: String) -> Bool {
        suggestions.contains { item in
            guard case let .perfume(name, _, _) = item else { return false }
            return registrationNameScore(name: name, query: query) > 0
        }
    }

    func registrationPerfumeNameResults(from perfumes: [Perfume]) -> [Perfume] {
        guard case let .result(query) = currentState else {
            return Array(perfumes.prefix(3))
        }

        return perfumes
            .map { perfume in (perfume: perfume, score: registrationNameScore(for: perfume, query: query)) }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                let lhsPriority = PerfumeKoreanTranslator.koreaBrandAvailabilityScore(for: lhs.perfume)
                let rhsPriority = PerfumeKoreanTranslator.koreaBrandAvailabilityScore(for: rhs.perfume)
                if lhsPriority != rhsPriority { return lhsPriority > rhsPriority }
                return lhs.perfume.name.localizedCaseInsensitiveCompare(rhs.perfume.name) == .orderedAscending
            }
            .prefix(3)
            .map(\.perfume)
    }

    func registrationSuggestionItems(from items: [SuggestionItem]) -> [SuggestionItem] {
        let query = searchTextRelay.value
        return items
            .filter { item in
                guard case let .perfume(name, _, _) = item else { return false }
                return registrationNameScore(name: name, query: query) > 0
            }
            .prefix(3)
            .map { $0 }
    }

    func registrationNameScore(for perfume: Perfume, query: String) -> Int {
        let queryCandidates = registrationSearchQueryCandidates(for: query)
        guard !queryCandidates.isEmpty else { return 0 }

        let nameValues = registrationSearchableNameValues(for: perfume)
            .map(registrationNormalizeForSearch(_:))

        for query in queryCandidates {
            if nameValues.contains(query) { return 1_000 }
            if nameValues.contains(where: { $0.hasPrefix(query) }) { return 900 }
            if nameValues.contains(where: { $0.contains(query) }) { return 800 }
            if nameValues.contains(where: { query.contains($0) && $0.count >= 2 }) { return 700 }
        }
        return 0
    }

    func registrationNameScore(name: String, query: String) -> Int {
        let queryCandidates = registrationSearchQueryCandidates(for: query)
        guard !queryCandidates.isEmpty else { return 0 }

        let nameValues = [name, PerfumePresentationSupport.displayPerfumeName(name)]
            .map(registrationNormalizeForSearch(_:))
            .filter { !$0.isEmpty }

        for query in queryCandidates {
            if nameValues.contains(query) { return 1_000 }
            if nameValues.contains(where: { $0.hasPrefix(query) }) { return 900 }
            if nameValues.contains(where: { $0.contains(query) }) { return 800 }
            if nameValues.contains(where: { query.contains($0) && $0.count >= 2 }) { return 700 }
        }
        return 0
    }

    func registrationSearchQueryCandidates(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates = [trimmed, PerfumeKoreanTranslator.toEnglishQuery(trimmed)]
            .compactMap { $0 }
            .map(registrationNormalizeForSearch(_:))
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }

    func registrationSearchableNameValues(for perfume: Perfume) -> [String] {
        let values = [perfume.name, PerfumePresentationSupport.displayPerfumeName(perfume.name)] + perfume.nameAliases
        var seen = Set<String>()
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert(registrationNormalizeForSearch($0)).inserted }
    }

    func registrationSearchableBrandValues(for perfume: Perfume) -> [String] {
        let values = [perfume.brand, PerfumePresentationSupport.displayBrand(perfume.brand)] + perfume.brandAliases
        var seen = Set<String>()
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert(registrationNormalizeForSearch($0)).inserted }
    }

    func openPendingRegisterSuggestionIfPossible() {
        guard mode == .register, let pendingRegisterSuggestion else { return }

        guard let perfume = filteredPerfumeResults.first(where: {
            registrationMatchesSuggestion($0, suggestion: pendingRegisterSuggestion)
        }) else {
            return
        }

        self.pendingRegisterSuggestion = nil
        registerCollectedPerfume(perfume)
    }

    func registrationMatchesSuggestion(
        _ perfume: Perfume,
        suggestion: (name: String, brand: String)
    ) -> Bool {
        let targetNameValues = [suggestion.name, PerfumePresentationSupport.displayPerfumeName(suggestion.name)]
            .map(registrationNormalizeForSearch(_:))
            .filter { !$0.isEmpty }
        let targetBrandValues = [suggestion.brand, PerfumePresentationSupport.displayBrand(suggestion.brand)]
            .map(registrationNormalizeForSearch(_:))
            .filter { !$0.isEmpty }

        let perfumeNameValues = registrationSearchableNameValues(for: perfume)
            .map(registrationNormalizeForSearch(_:))
        let perfumeBrandValues = registrationSearchableBrandValues(for: perfume)
            .map(registrationNormalizeForSearch(_:))

        let hasMatchingName = targetNameValues.contains { perfumeNameValues.contains($0) }
        let hasMatchingBrand = targetBrandValues.isEmpty
            || targetBrandValues.contains { perfumeBrandValues.contains($0) }
        return hasMatchingName && hasMatchingBrand
    }

    func registrationNormalizeForSearch(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    func sectionCountText(title: String, count: Int) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        result.append(
            NSAttributedString(
                string: "  \(count)개",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
        )
        return result
    }

    // MARK: - Filter/Sort

    func presentFilterSheet() {
        let filterVM = FilterViewModel(initialFilter: currentFilter)
        filterVM.currentPerfumes = allPerfumeResults
        let filterVC = FilterViewController(viewModel: filterVM)
        filterVC.modalPresentationStyle = .pageSheet
        if let sheet = filterVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        filterVC.onApply = { [weak self] filter in
            self?.filterChangedRelay.accept(filter)
        }
        present(filterVC, animated: true)
    }

    func presentSortActionSheet() {
        let sortSheet = SortBottomSheetViewController(
            currentSort: currentSort,
            onSelect: { [weak self] option in
                self?.sortChangedRelay.accept(option)
            }
        )
        sortSheet.modalPresentationStyle = .pageSheet
        if let sheet = sortSheet.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("sortOptions")) { _ in 262 }
            ]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(sortSheet, animated: true)
    }

    private func updateResultVisibility() {
        guard case let .result(query) = currentState else { return }

        let hasBrands = !brandResults.isEmpty
        let hasPerfumes = !filteredPerfumeResults.isEmpty

        if mode == .register {
            resultHeaderView.isHidden = true
            brandSectionLabel.isHidden = true
            brandTableView.isHidden = true
            brandEmptyLabel.isHidden = true
            perfumeCollectionView.isHidden = true
            tableView.isHidden = !hasPerfumes
            tableView.tableHeaderView = nil
            tableView.tableFooterView = nil
            tableView.reloadData()

            if !hasPerfumes {
                emptyView.configure(query: query)
                emptyView.isHidden = false
            } else {
                emptyView.isHidden = true
            }

            applyKeyboardInset()
            return
        }

        resultHeaderView.isHidden = false
        brandSectionLabel.isHidden = false
        brandTableView.isHidden = !hasBrands
        brandEmptyLabel.isHidden = hasBrands
        perfumeCollectionView.isHidden = !hasPerfumes
        brandSectionLabel.attributedText = makeCountAttributed(AppStrings.UIKitScreens.Search.brandCount(brandResults.count))
        resultHeaderTopToGuideConstraint?.deactivate()
        if hasBrands {
            resultHeaderTopToBrandEmptyConstraint?.deactivate()
            resultHeaderTopToBrandConstraint?.activate()
        } else {
            resultHeaderTopToBrandConstraint?.deactivate()
            resultHeaderTopToBrandEmptyConstraint?.activate()
        }

        brandEmptyLabel.text = hasBrands ? nil : AppStrings.UIKitScreens.Search.noBrandResults(query)

        if !hasPerfumes {
            emptyView.configure(query: query)
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }

        applyKeyboardInset()
    }
}

private extension SearchViewController {

    // MARK: - Keyboard

    func bindKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}

private extension SearchViewController {

    // MARK: - Likes

    @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return }

        let keyboardFrame = view.convert(keyboardFrameValue.cgRectValue, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)
        keyboardInset = overlap
        isKeyboardVisible = overlap > 0

        animateKeyboardInset(with: userInfo)
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        keyboardInset = 0
        isKeyboardVisible = false
        animateKeyboardInset(with: notification.userInfo)
    }

    private func animateKeyboardInset(with userInfo: [AnyHashable: Any]?) {
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue
            ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.applyKeyboardInset()
            self.view.layoutIfNeeded()
        }
    }

    private func applyKeyboardInset() {
        let bottomInset = keyboardInset + 16

        [tableView, brandTableView].forEach {
            $0.contentInset.bottom = bottomInset
            $0.verticalScrollIndicatorInsets.bottom = bottomInset
        }
        perfumeCollectionView.contentInset.bottom = bottomInset
        perfumeCollectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func loadLikedPerfumes() {
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.likedPerfumeIDs = Set(items.map(\.id))
                self?.reloadPerfumeResults()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    // MARK: - 결과 카운트 AttributedString 생성
    // "향수N개" → 향수(18SB) + N개(16M)
    private func makeCountAttributed(_ text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString()
        let parts = text.components(separatedBy: " ")
        guard parts.count >= 2 else {
            return NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.black
            ])
        }
        // 첫 단어: "향수"/"브랜드" (18SB, black)
        attributed.append(NSAttributedString(string: parts[0], attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: UIColor.black
        ]))
        // 공백: kern으로 8pt 간격
        attributed.append(NSAttributedString(string: " ", attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .kern: 3.5
        ]))
        // "N개" (16M, 중간 회색)
        attributed.append(NSAttributedString(string: parts[1...].joined(separator: " "), attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
        ]))
        return attributed
    }

    private func loadCollectedPerfumes() {
        collectionRepository.fetchCollection()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.ownedPerfumeIDs = Set(items.map(\.id))
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func loadTastingNoteKeys() {
        // 1단계: CoreData 로컬에서 즉시 반영 (동기)
        if let localNotes = try? localTastingNoteRepository.loadNotes() {
            tastingNoteKeys = Set(localNotes.flatMap {
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: $0.perfumeName,
                    brandName: $0.brandName
                )
            })
            reloadPerfumeResults()
        }

        // 2단계: Firestore에서 추가 병합 (비동기)
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
                self.reloadPerfumeResults()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func saveLikedPerfume(_ perfume: Perfume) {
        let collectionID = perfume.collectionDocumentID
        guard !likedPerfumeIDs.contains(collectionID) else { return }

        collectionRepository.saveLikedPerfume(perfume)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.insert(collectionID)
                self?.reloadPerfumeResults()
                NotificationCenter.default.post(name: .perfumeCollectionDidChange, object: nil)
            }, onError: { [weak self] error in
                self?.presentSaveFailure(error)
            })
            .disposed(by: disposeBag)
    }

    private func deleteLikedPerfume(id: String) {
        guard likedPerfumeIDs.contains(id) else { return }

        collectionRepository.deleteLikedPerfume(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.remove(id)
                self?.reloadPerfumeResults()
                NotificationCenter.default.post(name: .perfumeCollectionDidChange, object: nil)
            }, onError: { [weak self] error in
                self?.presentSaveFailure(error)
            })
            .disposed(by: disposeBag)
    }

    private func registerCollectedPerfume(_ perfume: Perfume) {
        guard mode == .register else { return }
        guard !isRegisteringCollection else { return }
        let collectionID = perfume.collectionDocumentID
        if ownedPerfumeIDs.contains(collectionID) {
            showAppToast(message: AppStrings.UIKitScreens.Search.registerDuplicate)
            return
        }

        presentCollectedPerfumeRegistration(for: perfume)
    }

    private func presentCollectedPerfumeRegistration(for perfume: Perfume) {
        let registrationViewController = CollectedPerfumeRegistrationViewController(perfume: perfume)
        registrationViewController.onRegister = { [weak self] info in
            self?.saveCollectedPerfume(perfume, registrationInfo: info, sourceViewController: registrationViewController)
        }
        registrationViewController.onRetrySearch = { [weak self] in
            self?.searchBar.becomeFirstResponder()
        }
        navigationController?.pushViewController(registrationViewController, animated: true)
    }

    private func saveCollectedPerfume(
        _ perfume: Perfume,
        registrationInfo: CollectedPerfumeRegistrationInfo,
        sourceViewController: UIViewController
    ) {
        let collectionID = perfume.collectionDocumentID
        isRegisteringCollection = true
        view.isUserInteractionEnabled = false
        sourceViewController.view.isUserInteractionEnabled = false

        collectionRepository.saveCollectedPerfume(perfume, registrationInfo: registrationInfo)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                guard let self else { return }
                self.isRegisteringCollection = false
                self.view.isUserInteractionEnabled = true
                sourceViewController.view.isUserInteractionEnabled = true
                self.ownedPerfumeIDs.insert(collectionID)
                NotificationCenter.default.post(name: .perfumeCollectionDidChange, object: nil)
                self.navigationController?.popToViewController(self, animated: false)
                self.presentCollectionRegisteredAlert(for: perfume)
            }, onError: { [weak self] error in
                guard let self else { return }
                self.isRegisteringCollection = false
                self.view.isUserInteractionEnabled = true
                sourceViewController.view.isUserInteractionEnabled = true
                if let limitError = error as? CollectionUsageLimitError {
                    sourceViewController.showAppToast(message: limitError.localizedDescription)
                } else {
                    let alert = UIAlertController(
                        title: nil,
                        message: AppStrings.UIKitScreens.Search.registerFailed,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
                    sourceViewController.present(alert, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }

    private func presentCollectionRegisteredAlert(for perfume: Perfume) {
        let perfumeName = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        let alert = UIAlertController(
            title: AppStrings.Collection.registerSuccessTitle,
            message: AppStrings.Collection.registerSuccessMessage(perfumeName),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: AppStrings.Collection.writeTastingNoteButton,
            style: .default
        ) { [weak self] _ in
            self?.presentTastingForm(for: perfume)
        })
        alert.addAction(UIAlertAction(
            title: AppStrings.Collection.doneButton,
            style: .cancel
        ) { [weak self] _ in
            self?.finishRegisterFlow()
        })
        present(alert, animated: true)
    }

    private func presentTastingForm(for perfume: Perfume) {
        let formView = TastingNoteSceneFactory.makeFormView(
            initialPerfume: perfume,
            isOwnedPerfumeContext: ownedPerfumeIDs.contains(perfume.collectionDocumentID)
        ) { [weak self] perfumeName in
            guard let self else { return }
            self.presentedTastingFormController?.dismiss(animated: true) {
                self.presentedTastingFormController = nil
                self.showAppToast(message: AppStrings.ViewModelMessages.TastingNote.saved(perfumeName))
                self.finishRegisterFlow()
            }
        }
        let hostingController = UIHostingController(rootView: formView)
        hostingController.modalPresentationStyle = .fullScreen
        presentedTastingFormController = hostingController
        present(hostingController, animated: true)
    }

    private func finishRegisterFlow() {
        guard mode == .register else { return }

        if let navigationController,
           navigationController.presentingViewController != nil,
           navigationController.viewControllers.first === self {
            navigationController.dismiss(animated: true)
        } else if (navigationController?.viewControllers.count ?? 0) > 1 {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func presentSaveFailure(_ error: Error) {
        if let limitError = error as? CollectionUsageLimitError {
            showAppToast(message: limitError.localizedDescription)
            return
        }

        let message = mode == .register
            ? AppStrings.UIKitScreens.Search.registerFailed
            : AppStrings.UIKitScreens.Search.likeSaveFailed
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
        present(alert, animated: true)
    }

    private func updateSearchBarLeadingConstraint() {
        let showsBackButton = !backButton.isHidden
        if showsBackButton {
            searchBarLeadingToSuperviewConstraint?.deactivate()
            searchBarLeadingToBackConstraint?.activate()
        } else {
            searchBarLeadingToBackConstraint?.deactivate()
            searchBarLeadingToSuperviewConstraint?.activate()
        }
        view.layoutIfNeeded()
    }
}

    // MARK: - UITableViewDataSource & Delegate

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == brandTableView {
            return min(brandResults.count, 1)
        }
        switch currentState {
            case .landing:
                return 0
            case .initial:
                // 자동저장 꺼짐 → 안내 셀 1개만 표시
                if !isAutoSaveEnabled { return 1 }
                return recentSearches.isEmpty ? 1 : recentSearches.count
            case .suggesting:
                return suggestions.count
            case .result:
                return mode == .register ? filteredPerfumeResults.count : 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // 브랜드 테이블뷰
        if tableView == brandTableView {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: BrandResultCell.identifier,
                for: indexPath
            ) as! BrandResultCell
            let brand = brandResults[indexPath.row]
            cell.configure(with: brand)
            return cell
        }

            // 초기 상태 — 최근 검색어
        if case .initial = currentState {
            if !isAutoSaveEnabled || recentSearches.isEmpty {
                    // 자동저장 꺼짐 안내 or 빈 상태 안내
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: SearchMessageCell.identifier,
                    for: indexPath
                ) as! SearchMessageCell
                let message = !isAutoSaveEnabled
                    ? "검색어 저장 기능이 꺼져 있습니다."
                    : AppStrings.UIKitScreens.Search.noRecent
                cell.configure(message: message, topInset: 40)
                return cell
            }
            let cell = tableView.dequeueReusableCell(
                withIdentifier: RecentSearchCell.identifier,
                for: indexPath
            ) as! RecentSearchCell
            cell.configure(with: recentSearches[indexPath.row])

                // 개별 삭제 버튼
            cell.deleteButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self else { return }
                    let query = self.recentSearches[indexPath.row].query
                    self.deleteRecentSearchRelay.accept(query)
                })
                .disposed(by: cell.disposeBag)

            return cell
        }

            // 타이핑 중 — 연관 검색어 (썸네일 이미지 URL 포함)
        if case .suggesting = currentState {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SuggestionCell.identifier,
                for: indexPath
            ) as! SuggestionCell
            let item = suggestions[indexPath.row]
            cell.configure(with: item, query: searchTextRelay.value, imageUrl: item.imageUrl)
            return cell
        }

        if case .result = currentState, mode == .register {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: PerfumeSearchResultCell.identifier,
                for: indexPath
            ) as! PerfumeSearchResultCell
            cell.configure(with: filteredPerfumeResults[indexPath.row])
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

            // 브랜드 테이블뷰
        if tableView == brandTableView {
            let brand = brandResults[indexPath.row]
            let query = PerfumePresentationSupport.displayBrand(brand.brand)
            searchBar.text = query
            searchTextRelay.accept(query)
            updateSearchBarAccessory(for: query)
            searchTriggerRelay.accept(query)
            return
        }

            // 초기 상태 — 최근 검색어 탭 (자동저장 켜짐이고 검색어 있을 때만)
        if case .initial = currentState, isAutoSaveEnabled, !recentSearches.isEmpty {
            guard mode != .register else { return }
            let query = recentSearches[indexPath.row].query
            searchBar.text = query
            searchTextRelay.accept(query)
            updateSearchBarAccessory(for: query)
            recentSearchTapRelay.accept(query)
            return
        }

            // 타이핑 중 — 연관 검색어 탭
        if case .suggesting = currentState {
            let item = suggestions[indexPath.row]
            let query = item.displayName
            if mode == .register, case let .perfume(name, brand, _) = item {
                pendingRegisterSuggestion = (name: name, brand: brand)
            }
            searchBar.text = query
            searchTextRelay.accept(query)
            updateSearchBarAccessory(for: query)
            searchTriggerRelay.accept(query)
            searchBar.resignFirstResponder()
            return
        }

        if case .result = currentState, mode == .register {
            registerCollectedPerfume(filteredPerfumeResults[indexPath.row])
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard tableView != brandTableView else { return 84 }

        if case .result = currentState, mode == .register {
            return 74
        }

        if case .initial = currentState, !isAutoSaveEnabled || recentSearches.isEmpty {
            return 180
        }

        return UITableView.automaticDimension
    }

        // 빈 상태 또는 자동저장 꺼짐 안내 셀은 선택 비활성화
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if case .initial = currentState {
            if !isAutoSaveEnabled || recentSearches.isEmpty {
                return false
            }
        }
        return true
    }
}

    // MARK: - UICollectionViewDataSource & Delegate

extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredPerfumeResults.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PerfumeGridCell.identifier,
            for: indexPath
        ) as! PerfumeGridCell
        let perfume = filteredPerfumeResults[indexPath.item]
        let collectionID = perfume.collectionDocumentID
        let hasTastingRecord = !tastingNoteKeys.isDisjoint(
            with: PerfumePresentationSupport.recordMatchingKeys(
                perfumeName: perfume.name,
                brandName: perfume.brand
            )
        )
        cell.configure(
            with: perfume,
            isLiked: likedPerfumeIDs.contains(collectionID),
            hasTastingRecord: hasTastingRecord
        )

            // 찜하기 버튼
        cell.wishlistButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.likedPerfumeIDs.contains(collectionID) {
                    self.deleteLikedPerfume(id: collectionID)
                } else {
                    self.saveLikedPerfume(perfume)
                }
            })
            .disposed(by: cell.disposeBag)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let perfume = filteredPerfumeResults[indexPath.item]
        if mode == .register {
            registerCollectedPerfume(perfume)
            return
        }

        let detailVC = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let horizontalInset: CGFloat = 48
        let spacing: CGFloat = 16
        let width = floor((collectionView.bounds.width - horizontalInset - spacing) / 2)
        return CGSize(width: width, height: width + 100)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 18, left: 24, bottom: 110, right: 24)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        20
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        16
    }
}

private final class BrandResultCell: UITableViewCell {
    static let identifier = "BrandResultCell"

    private let thumbnailContainerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 14
        $0.layer.cornerCurve = .continuous
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(hex: "#E9E5DF").cgColor
        $0.clipsToBounds = true
    }

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private let brandNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 20, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 1
    }

    private let brandEnglishLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
    }

    func configure(with perfume: Perfume) {
        brandNameLabel.text = PerfumePresentationSupport.displayBrand(perfume.brand)
        brandEnglishLabel.text = perfume.brand.uppercased()

        if let imageUrl = perfume.imageUrl, let url = URL(string: imageUrl) {
            thumbnailImageView.kf.setImage(with: url)
        }
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        [thumbnailContainerView, brandNameLabel, brandEnglishLabel].forEach {
            contentView.addSubview($0)
        }
        thumbnailContainerView.addSubview(thumbnailImageView)

        thumbnailContainerView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(64)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(7)
        }

        brandNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.equalTo(thumbnailContainerView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview()
        }

        brandEnglishLabel.snp.makeConstraints {
            $0.top.equalTo(brandNameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(brandNameLabel)
            $0.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
    }
}

private final class PerfumeSearchResultCell: UITableViewCell {
    static let identifier = "PerfumeSearchResultCell"

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 12
        $0.layer.cornerCurve = .continuous
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1).cgColor
        $0.backgroundColor = .systemGray6
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 2
        $0.lineBreakMode = .byWordWrapping
    }

    private let brandLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
        nameLabel.text = nil
        brandLabel.text = nil
    }

    func configure(with perfume: Perfume) {
        nameLabel.text = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        brandLabel.text = PerfumePresentationSupport.displayBrand(perfume.brand)

        if let imageUrl = perfume.imageUrl, let url = URL(string: imageUrl) {
            thumbnailImageView.kf.setImage(with: url)
        }
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        [thumbnailImageView, nameLabel, brandLabel].forEach {
            contentView.addSubview($0)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(6)
            $0.bottom.lessThanOrEqualToSuperview().offset(-6)
            $0.size.equalTo(62)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-16)
        }

        brandLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-6)
        }
    }
}

private final class SearchMessageCell: UITableViewCell {
    static let identifier = "SearchMessageCell"

    private let messageLabel = UILabel().then {
        $0.font = UIFont(name: "Pretendard-Medium", size: 16)
            ?? UIFont(name: "Pretendard", size: 16)
            ?? .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1)
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }

    private var topConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(message: String, topInset: CGFloat) {
        messageLabel.text = message
        topConstraint?.update(offset: topInset)
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        contentView.addSubview(messageLabel)

        messageLabel.snp.makeConstraints {
            topConstraint = $0.top.equalToSuperview().offset(40).constraint
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
