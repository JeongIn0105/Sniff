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
import Kingfisher

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
        $0.contentHorizontalAlignment = .center
    }

    // 상단 검색바
    let searchBar = UISearchBar().then {
        $0.placeholder = AppStrings.UIKitScreens.Search.placeholder
        $0.searchBarStyle = .minimal
        $0.returnKeyType = .search
        $0.searchTextField.font = SearchStyle.pretendard(size: 16, weight: .medium)
        $0.searchTextField.clearButtonMode = .never
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
        $0.register(SearchMessageCell.self, forCellReuseIdentifier: SearchMessageCell.identifier)
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
        $0.rowHeight = 84
        $0.isHidden = true
        $0.isScrollEnabled = false
        $0.keyboardDismissMode = .onDrag
        $0.backgroundColor = .systemBackground
    }

    // 향수 그리드
    lazy var perfumeCollectionView: UICollectionView = {
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
    let emptyView = SearchEmptyView().then {
        $0.isHidden = true
    }

    // 최근 검색어 헤더 (초기 상태)
    let recentHeaderView = UIView()
    let recentTitleLabel = UILabel().then {
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
    let clearAllButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.clearAll, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = SearchStyle.pretendard(size: 14, weight: .medium)
        $0.contentHorizontalAlignment = .left
        $0.isHidden = true
    }
    let recentFooterView = UIView()
    let footerClearAllButton = UIButton(type: .system).then {
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

    var resultHeaderTopToGuideConstraint: Constraint?
    var resultHeaderTopToBrandConstraint: Constraint?
    var resultHeaderTopToBrandEmptyConstraint: Constraint?
    var searchBarLeadingToBackConstraint: Constraint?
    var searchBarLeadingToSuperviewConstraint: Constraint?

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
