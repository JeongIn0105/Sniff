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
    private let viewModel: SearchViewModel
    private let collectionRepository: CollectionRepositoryType
    private let tastingRecordRepository: TastingRecordRepositoryType
    private let localTastingNoteRepository: LocalTastingNoteRepository
    private let showsRecentOnAppear: Bool
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
    private var tastingNoteKeys = Set<String>()
    private var hasHandledRecentOnAppear = false

        // MARK: - UI Components

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
        $0.isHidden = true
    }

        // 상단 검색바
    private let searchBar = UISearchBar().then {
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

    private let filterButton = UIButton(type: .system).then {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        $0.setImage(UIImage(systemName: "slider.horizontal.3", withConfiguration: symbolConfig), for: .normal)
        $0.tintColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
    }

    // 향수N개 | 필터 사이 구분선 (Atomic/Neutral/200, 2×20pt)
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
        $0.separatorStyle = .none
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 68
        $0.backgroundColor = .systemBackground
        $0.keyboardDismissMode = .onDrag
    }

        // 브랜드 가로 스크롤 (결과 화면)
    private lazy var brandTableView = UITableView().then {
        $0.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.identifier)
        $0.separatorStyle = .none
        $0.rowHeight = 64
        $0.isHidden = true
        $0.isScrollEnabled = false
        $0.keyboardDismissMode = .onDrag
    }

        // 향수 그리드
    private lazy var perfumeCollectionView: UICollectionView = {
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
    private let emptyView = SearchEmptyView().then {
        $0.isHidden = true
    }

        // 최근 검색어 헤더 (초기 상태)
    private let recentHeaderView = UIView()
    private let recentTitleLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.Search.recentTitle
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
    }
    private let clearAllButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.clearAll, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13)
        $0.isHidden = true
    }
    private let recentFooterView = UIView()
    private let footerClearAllButton = UIButton(type: .system).then {
        $0.setTitle(AppStrings.UIKitScreens.Search.clearAll, for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.contentHorizontalAlignment = .left
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
        showsRecentOnAppear: Bool = false
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
        self.tastingRecordRepository = tastingRecordRepository
        self.localTastingNoteRepository = localTastingNoteRepository
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
        loadTastingNoteKeys()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard showsRecentOnAppear, !hasHandledRecentOnAppear else { return }
        hasHandledRecentOnAppear = true
        searchBar.becomeFirstResponder()
    }
}

private extension SearchViewController {

    // MARK: - UI Setup

    func setupUI() {
        view.backgroundColor = .systemBackground


        setupRecentHeader()
        addSubviews()
        makeConstraints()
        updateSearchBarLeadingConstraint()
        resultHeaderTopToBrandConstraint?.deactivate()
        resultHeaderTopToBrandEmptyConstraint?.deactivate()
    }

    func setupRecentHeader() {
        recentHeaderView.addSubview(recentTitleLabel)
        recentTitleLabel.frame = CGRect(x: 20, y: 6, width: 200, height: 32)
        recentTitleLabel.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        recentHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)

        recentFooterView.addSubview(footerClearAllButton)
        footerClearAllButton.frame = CGRect(x: 20, y: 0, width: 120, height: 44)
        footerClearAllButton.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        recentFooterView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
    }

    func addSubviews() {
        [backButton, searchBar, resultHeaderView,
         landingGuideLabel,
         brandSectionLabel, brandEmptyLabel, brandTableView,
         tableView, perfumeCollectionView, emptyView].forEach {
            view.addSubview($0)
        }

        [resultCountLabel, countSeparatorView, filterButton, sortButton].forEach { resultHeaderView.addSubview($0) }
    }

    func makeConstraints() {
        backButton.snp.makeConstraints {
            $0.centerY.equalTo(searchBar.snp.centerY)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(28)
        }

        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            searchBarLeadingToBackConstraint = $0.leading.equalTo(backButton.snp.trailing).offset(4).constraint
            searchBarLeadingToSuperviewConstraint = $0.leading.equalToSuperview().offset(16).constraint
            $0.trailing.equalToSuperview().offset(-8)
        }

        landingGuideLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        resultHeaderView.snp.makeConstraints {
            resultHeaderTopToGuideConstraint = $0.top.equalTo(landingGuideLabel.snp.bottom).offset(8).constraint
            resultHeaderTopToBrandConstraint = $0.top.equalTo(brandTableView.snp.bottom).offset(20).constraint
            resultHeaderTopToBrandEmptyConstraint = $0.top.equalTo(brandEmptyLabel.snp.bottom).offset(20).constraint
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }
        resultCountLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        // | 구분선: 2×20pt, Atomic/Neutral/200
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
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }

        brandSectionLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(18)
            $0.leading.equalToSuperview().offset(20)
        }

        brandTableView.snp.makeConstraints {
            $0.top.equalTo(brandSectionLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
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
        recentHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
        recentFooterView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
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
                self.suggestions = items
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
                    $0.height.equalTo(brands.isEmpty ? 0 : brands.count * 56)
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
                self.filteredPerfumeResults = perfumes
                self.reloadPerfumeResults()
                self.updateResultVisibility()
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
                // 필터 활성화 여부에 따라 아이콘 색상만 변경 (필 스타일 없음)
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
            .bind(to: searchTextRelay)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .withLatestFrom(searchTextRelay)
            .bind(to: searchTriggerRelay)
            .disposed(by: disposeBag)

        searchBar.rx.textDidBeginEditing
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.currentState = .initial
                self.updateLayout(for: .initial)
            })
            .disposed(by: disposeBag)

        searchBar.rx.cancelButtonClicked
            .bind(to: clearTriggerRelay)
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

        footerClearAllButton.rx.tap
            .bind(to: clearAllRecentSearchesRelay)
            .disposed(by: disposeBag)

        backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
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
    }

    func showInitialLayout() {
        tableView.isHidden = false
        resultHeaderView.isHidden = true
        landingGuideLabel.isHidden = true
        brandSectionLabel.isHidden = true
        brandEmptyLabel.isHidden = true
        brandTableView.isHidden = true
        perfumeCollectionView.isHidden = true
        emptyView.isHidden = true
        searchBar.showsCancelButton = false
        updateRecentTableChrome()
        reloadTableView()
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
        searchBar.showsCancelButton = false
        tableView.tableHeaderView = nil
        tableView.tableFooterView = nil
        reloadTableView()
    }

    func showResultLayout() {
        tableView.isHidden = true
        resultHeaderView.isHidden = false
        landingGuideLabel.isHidden = true
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        tableView.tableFooterView = nil
        updateResultVisibility()
    }

    func showLandingLayout() {
        tableView.isHidden = true
        resultHeaderView.isHidden = false
        landingGuideLabel.isHidden = true
        brandSectionLabel.isHidden = false
        brandTableView.isHidden = true
        perfumeCollectionView.isHidden = true
        emptyView.isHidden = false
        brandEmptyLabel.isHidden = false
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
    }

    func reloadTableView() {
        tableView.reloadData()
    }

    func updateRecentTableChrome() {
        recentTitleLabel.isHidden = recentSearches.isEmpty
        clearAllButton.isHidden = true
        recentHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
        recentFooterView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44)
        tableView.tableHeaderView = recentSearches.isEmpty ? nil : recentHeaderView
        tableView.tableFooterView = recentSearches.count > 1 ? recentFooterView : nil
    }

    func reloadPerfumeResults() {
        perfumeCollectionView.reloadData()
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
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(sortSheet, animated: true)
    }

    private func updateResultVisibility() {
        guard case let .result(query) = currentState else { return }

        let hasBrands = !brandResults.isEmpty
        let hasPerfumes = !filteredPerfumeResults.isEmpty

        resultHeaderView.isHidden = false
        brandSectionLabel.isHidden = false
        brandTableView.isHidden = !hasBrands
        brandEmptyLabel.isHidden = hasBrands
        perfumeCollectionView.isHidden = !hasPerfumes
        brandSectionLabel.attributedText = makeCountAttributed(AppStrings.UIKitScreens.Search.brandCount(brandResults.count))
        resultHeaderTopToGuideConstraint?.deactivate()
        resultHeaderTopToBrandConstraint?.isActive = hasBrands
        resultHeaderTopToBrandEmptyConstraint?.isActive = !hasBrands

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
        animateKeyboardInset(with: userInfo)
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        keyboardInset = 0
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
    // "향수 N개" → 향수(18SB) + N개(16M)
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
        // 공백: kern으로 8pt 간격 (space advance ~4.5pt + kern 3.5 ≈ 8pt)
        attributed.append(NSAttributedString(string: " ", attributes: [
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
            .kern: 3.5
        ]))
        // "N개" (16M, Atomic/Neutral/700)
        attributed.append(NSAttributedString(string: parts[1...].joined(separator: " "), attributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
        ]))
        return attributed
    }

    private func loadTastingNoteKeys() {
        // 1단계: CoreData 로컬에서 즉시 반영 (동기) — Firestore 동기화 전에도 배지 표시
        if let localNotes = try? localTastingNoteRepository.loadNotes() {
            tastingNoteKeys = Set(localNotes.flatMap {
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: $0.perfumeName,
                    brandName: $0.brandName
                )
            })
            reloadPerfumeResults()
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

    private func presentSaveFailure(_ error: Error) {
        if let limitError = error as? CollectionUsageLimitError {
            showAppToast(message: limitError.localizedDescription)
            return
        }

        let alert = UIAlertController(title: nil, message: AppStrings.UIKitScreens.Search.likeSaveFailed, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
        present(alert, animated: true)
    }

    private func updateSearchBarLeadingConstraint() {
        let showsBackButton = !backButton.isHidden
        searchBarLeadingToBackConstraint?.isActive = showsBackButton
        searchBarLeadingToSuperviewConstraint?.isActive = !showsBackButton
        view.layoutIfNeeded()
    }
}

    // MARK: - UITableViewDataSource & Delegate

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == brandTableView {
            return brandResults.count
        }
        switch currentState {
            case .landing:
                return 0
            case .initial:
                return recentSearches.isEmpty ? 1 : recentSearches.count // 1 = 빈 상태 안내 셀
            case .suggesting:
                return suggestions.count
            case .result:
                return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // 브랜드 테이블뷰
        if tableView == brandTableView {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SuggestionCell.identifier,
                for: indexPath
            ) as! SuggestionCell
            let brand = brandResults[indexPath.row]
            cell.configure(
                with: .brand(name: brand.brand),
                query: searchTextRelay.value,
                imageUrl: brand.imageUrl
            )
            return cell
        }

            // 초기 상태 — 최근 검색어
        if case .initial = currentState {
            if recentSearches.isEmpty {
                    // 빈 상태 안내
                let cell = UITableViewCell()
                cell.selectionStyle = .none
                cell.textLabel?.text = AppStrings.UIKitScreens.Search.noRecent
                cell.textLabel?.textColor = .secondaryLabel
                cell.textLabel?.font = .systemFont(ofSize: 14)
                cell.textLabel?.textAlignment = .center
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

            // 타이핑 중 — 연관 검색어
        if case .suggesting = currentState {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SuggestionCell.identifier,
                for: indexPath
            ) as! SuggestionCell
            let item = suggestions[indexPath.row]
            cell.configure(with: item, query: searchTextRelay.value)
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

            // 브랜드 테이블뷰
        if tableView == brandTableView {
            let brand = brandResults[indexPath.row]
            searchTriggerRelay.accept(brand.brand)
            return
        }

            // 초기 상태 — 최근 검색어 탭
        if case .initial = currentState, !recentSearches.isEmpty {
            recentSearchTapRelay.accept(recentSearches[indexPath.row].query)
            return
        }

            // 타이핑 중 — 연관 검색어 탭
        if case .suggesting = currentState {
            let item = suggestions[indexPath.row]
            suggestionTapRelay.accept(item)
            searchBar.text = item.displayName
            searchBar.resignFirstResponder()
            return
        }
    }

        // 빈 상태일 때 셀 선택 비활성화
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if case .initial = currentState, recentSearches.isEmpty {
            return false
        }
        return true
    }
}

    // MARK: - UICollectionViewDataSource & Delegate

extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegate {

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
        let detailVC = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

    // MARK: - SearchEmptyView

final class SearchEmptyView: UIView {

    private let label = UILabel().then {
        $0.textAlignment = .center
        $0.textColor = .secondaryLabel
        $0.font = .systemFont(ofSize: 15)
        $0.numberOfLines = 0
    }

    init() {
        super.init(frame: .zero)
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(query: String) {
        label.text = AppStrings.UIKitScreens.Search.noResults(query)
    }

    func configureLanding() {
        label.text = AppStrings.UIKitScreens.Search.landingPerfumeMessage
    }
}

final class SortBottomSheetViewController: UIViewController {
    private let currentSort: SortOption
    private let onSelect: (SortOption) -> Void

    init(currentSort: SortOption, onSelect: @escaping (SortOption) -> Void) {
        self.currentSort = currentSort
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(24)
        }

        [SortOption.recommended, .nameAsc, .nameDesc].forEach { option in
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = option.displayName
            configuration.baseForegroundColor = .label
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 0, bottom: 18, trailing: 0)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 16, weight: .medium)
                return outgoing
            }
            if option == currentSort {
                configuration.image = UIImage(systemName: "checkmark")
                configuration.imagePlacement = .trailing
                configuration.imagePadding = 12
            }
            button.configuration = configuration
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in
                self?.dismiss(animated: true) {
                    self?.onSelect(option)
                }
            }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }
}
