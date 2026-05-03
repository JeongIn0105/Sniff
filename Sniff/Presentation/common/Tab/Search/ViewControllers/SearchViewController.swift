//
//  SearchViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//
// 킁킁(Sniff) - 검색 메인 ViewController

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class SearchViewController: UIViewController {

    // MARK: - Properties

    let viewModel: SearchViewModel
    let collectionRepository: CollectionRepositoryType
    let showsRecentOnAppear: Bool
    let disposeBag = DisposeBag()

    let searchTextRelay = BehaviorRelay<String>(value: "")
    let searchTriggerRelay = PublishRelay<String>()
    let clearTriggerRelay = PublishRelay<Void>()
    let recentSearchTapRelay = PublishRelay<String>()
    let suggestionTapRelay = PublishRelay<SuggestionItem>()
    let deleteRecentSearchRelay = PublishRelay<String>()
    let clearAllRecentSearchesRelay = PublishRelay<Void>()
    let filterChangedRelay = PublishRelay<SearchFilter>()
    let sortChangedRelay = PublishRelay<SortOption>()

    var currentState: SearchState
    var currentFilter: SearchFilter = SearchFilter()
    var currentSort: SortOption = .recommended
    var brandResults: [Perfume] = []
    var allPerfumeResults: [Perfume] = []
    var filteredPerfumeResults: [Perfume] = []

    // 테이블뷰 로컬 캐시 - ViewModel output을 받아 저장
    var recentSearches: [RecentSearch] = []
    var suggestions: [SuggestionItem] = []
    var keyboardInset: CGFloat = 0
    var likedPerfumeIDs = Set<String>()
    var hasHandledRecentOnAppear = false

    // MARK: - UI Components

    let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
        $0.isHidden = true
    }

    // 상단 검색바
    let searchBar = UISearchBar().then {
        $0.placeholder = AppStrings.UIKitScreens.Search.placeholder
        $0.searchBarStyle = .minimal
        $0.returnKeyType = .search
        $0.searchTextField.font = .systemFont(ofSize: 15, weight: .regular)
        $0.searchTextField.clearButtonMode = .whileEditing
        $0.searchTextField.attributedPlaceholder = NSAttributedString(
            string: AppStrings.UIKitScreens.Search.placeholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
    }

    let landingGuideLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        $0.text = AppStrings.UIKitScreens.Search.landingGuideMessage
        $0.isHidden = true
    }

    // 결과 카운트 + 필터 버튼 + 정렬 버튼
    let resultHeaderView = UIView().then {
        $0.isHidden = true
    }

    let resultCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .label
    }

    let filterButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        $0.setTitleColor(.label, for: .normal)
        $0.tintColor = .label
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 16
        $0.semanticContentAttribute = .forceLeftToRight
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        $0.configuration = configuration
    }

    let sortButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.sortRecommended, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        $0.setTitleColor(.label, for: .normal)
    }

    // 브랜드 섹션 (결과 화면)
    let brandSectionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.isHidden = true
    }

    let brandEmptyLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        $0.isHidden = true
    }

    // 메인 테이블뷰 - 초기/연관 검색어
    lazy var tableView = UITableView().then {
        $0.register(RecentSearchCell.self, forCellReuseIdentifier: RecentSearchCell.identifier)
        $0.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.identifier)
        $0.separatorStyle = .none
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 68
        $0.backgroundColor = .systemBackground
        $0.keyboardDismissMode = .onDrag
    }

    // 브랜드 가로 스크롤 (결과 화면)
    lazy var brandTableView = UITableView().then {
        $0.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.identifier)
        $0.separatorStyle = .none
        $0.rowHeight = 64
        $0.isHidden = true
        $0.isScrollEnabled = false
        $0.keyboardDismissMode = .onDrag
    }

    // 향수 그리드
    lazy var perfumeCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 16
        let itemWidth = (UIScreen.main.bounds.width - spacing * 3) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 70)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 16, left: spacing, bottom: 16, right: spacing)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(PerfumeGridCell.self, forCellWithReuseIdentifier: PerfumeGridCell.identifier)
        cv.backgroundColor = .systemBackground
        cv.isHidden = true
        cv.keyboardDismissMode = .onDrag
        return cv
    }()

    // 빈 상태 뷰
    let emptyView = SearchEmptyView().then {
        $0.isHidden = true
    }

    // 최근 검색어 헤더 (초기 상태)
    let recentHeaderView = UIView()
    let recentTitleLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Search.recentTitle
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
    }
    let clearAllButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.clearAll, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13)
        $0.isHidden = true
    }
    let recentFooterView = UIView()
    let footerClearAllButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.clearAll, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.contentHorizontalAlignment = .left
    }

    var resultHeaderTopToGuideConstraint: Constraint?
    var resultHeaderTopToBrandConstraint: Constraint?
    var resultHeaderTopToBrandEmptyConstraint: Constraint?
    var searchBarLeadingToBackConstraint: Constraint?
    var searchBarLeadingToSuperviewConstraint: Constraint?

    // MARK: - Init

    init(
        viewModel: SearchViewModel,
        collectionRepository: CollectionRepositoryType,
        showsRecentOnAppear: Bool = false
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
        self.showsRecentOnAppear = showsRecentOnAppear
        self.currentState = showsRecentOnAppear ? .initial : .landing
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
        backButton.isHidden = (navigationController?.viewControllers.count ?? 0) <= 1
        updateSearchBarLeadingConstraint()
        loadLikedPerfumes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard showsRecentOnAppear, !hasHandledRecentOnAppear else { return }
        hasHandledRecentOnAppear = true
        searchBar.becomeFirstResponder()
    }
}
