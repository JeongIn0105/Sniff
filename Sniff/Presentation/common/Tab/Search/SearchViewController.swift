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

    private var currentState: SearchState = .initial
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

        // MARK: - UI Components

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
        $0.isHidden = true
    }

        // 상단 검색바
    private let searchBar = UISearchBar().then {
        $0.placeholder = "향수명 또는 브랜드를 검색하세요"
        $0.searchBarStyle = .minimal
        $0.returnKeyType = .search
    }

        // 결과 카운트 + 필터 버튼 + 정렬 버튼
    private let resultHeaderView = UIView().then {
        $0.isHidden = true
    }

    private let resultCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .label
    }

    private let filterButton = UIButton(type: .system).then {
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

    private let sortButton = UIButton(type: .system).then {
        $0.setTitle("추천순 ▾", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13)
        $0.setTitleColor(.label, for: .normal)
    }

        // 브랜드 섹션 (결과 화면)
    private let brandSectionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .semibold)
        $0.isHidden = true
    }

        // 메인 테이블뷰 — 초기/연관 검색어
    private lazy var tableView = UITableView().then {
        $0.register(RecentSearchCell.self, forCellReuseIdentifier: RecentSearchCell.identifier)
        $0.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.identifier)
        $0.separatorStyle = .none
        $0.rowHeight = 52
        $0.backgroundColor = .systemBackground
        $0.keyboardDismissMode = .onDrag
    }

        // 브랜드 가로 스크롤 (결과 화면)
    private lazy var brandTableView = UITableView().then {
        $0.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.identifier)
        $0.separatorStyle = .none
        $0.rowHeight = 56
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
        $0.text = "Recent"
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
    }
    private let clearAllButton = UIButton(type: .system).then {
        $0.setTitle("모두 지우기", for: .normal)
        $0.setTitleColor(.systemRed, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 13)
        $0.isHidden = true
    }

        // MARK: - Init

    init(
        viewModel: SearchViewModel,
        collectionRepository: CollectionRepositoryType = CollectionRepository()
    ) {
        self.viewModel = viewModel
        self.collectionRepository = collectionRepository
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
        loadLikedPerfumes()
    }

        // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

            // 최근 검색어 헤더
        [recentTitleLabel, clearAllButton].forEach { recentHeaderView.addSubview($0) }
        recentTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        clearAllButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }
        recentHeaderView.snp.makeConstraints { $0.height.equalTo(44) }

            // 전체 레이아웃
        [backButton, searchBar, resultHeaderView,
         brandSectionLabel, brandTableView,
         tableView, perfumeCollectionView, emptyView].forEach {
            view.addSubview($0)
        }

        backButton.snp.makeConstraints {
            $0.centerY.equalTo(searchBar.snp.centerY)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(28)
        }

        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            $0.leading.equalTo(backButton.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().offset(-8)
        }

            // 결과 헤더 (카운트 + 필터 + 정렬)
        [resultCountLabel, filterButton, sortButton].forEach { resultHeaderView.addSubview($0) }
        resultHeaderView.snp.makeConstraints {
            $0.top.equalTo(brandTableView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }
        resultCountLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        filterButton.snp.makeConstraints {
            $0.leading.equalTo(resultCountLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(32)
            $0.trailing.lessThanOrEqualTo(sortButton.snp.leading).offset(-8)
        }
        sortButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }

        brandSectionLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(20)
            $0.height.equalTo(0)
        }

        brandTableView.snp.makeConstraints {
            $0.top.equalTo(brandSectionLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0)
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
            $0.center.equalToSuperview()
        }
    }

        // MARK: - TableView Setup

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        brandTableView.delegate = self
        brandTableView.dataSource = self

            // 테이블 헤더 (초기 상태 - Recent)
        tableView.tableHeaderView = recentHeaderView
        recentHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
    }

        // MARK: - CollectionView Setup

    private func setupCollectionView() {
        perfumeCollectionView.delegate = self
        perfumeCollectionView.dataSource = self
    }

        // MARK: - Bind ViewModel

    private func bindViewModel() {
        let input = SearchViewModel.Input(
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

            // 상태 변화
        output.state
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.currentState = state
                self?.updateLayout(for: state)
            })
            .disposed(by: disposeBag)

            // 최근 검색어
        output.recentSearches
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] searches in
                guard let self else { return }
                self.recentSearches = searches
                if case .initial = self.currentState {
                    self.clearAllButton.isHidden = searches.isEmpty
                    self.tableView.reloadData()
                }
            })
            .disposed(by: disposeBag)

            // 연관 검색어
        output.suggestions
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] items in
                guard let self else { return }
                self.suggestions = items
                if case .suggesting = self.currentState {
                    self.tableView.reloadData()
                }
            })
            .disposed(by: disposeBag)

            // 브랜드 결과
        output.brandResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] brands in
                guard let self else { return }
                self.brandResults = brands
                self.brandSectionLabel.text = "브랜드 \(brands.count)개"
                self.brandSectionLabel.snp.updateConstraints {
                    $0.height.equalTo(brands.isEmpty ? 0 : 22)
                }
                self.brandTableView.snp.updateConstraints {
                    $0.height.equalTo(brands.isEmpty ? 0 : min(brands.count * 56, 168))
                }
                self.brandTableView.reloadData()
                self.updateResultVisibility()
            })
            .disposed(by: disposeBag)

        output.perfumeResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfumes in
                self?.allPerfumeResults = perfumes
            })
            .disposed(by: disposeBag)

            // 향수 결과 (필터 적용)
        output.filteredPerfumeResults
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] perfumes in
                guard let self else { return }
                self.filteredPerfumeResults = perfumes
                self.perfumeCollectionView.reloadData()
                self.updateResultVisibility()
            })
            .disposed(by: disposeBag)

            // 결과 수
        output.resultCount
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                self?.resultCountLabel.text = "향수 \(count)개"
            })
            .disposed(by: disposeBag)

            // 현재 필터
        output.activeFilter
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                guard let self else { return }
                self.currentFilter = filter
                    // 필터 버튼 레이블 업데이트
                let label = filter.summaryLabel.map { "  \($0)" } ?? ""
                let image = UIImage(systemName: "slider.horizontal.3")
                self.filterButton.setTitle(label, for: .normal)
                self.filterButton.setImage(image, for: .normal)
                self.filterButton.backgroundColor = filter.isEmpty ? .systemGray5 : .label
                self.filterButton.tintColor = filter.isEmpty ? .label : .white
                self.filterButton.setTitleColor(filter.isEmpty ? .label : .white, for: .normal)
            })
            .disposed(by: disposeBag)

            // 정렬
        output.currentSort
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] sort in
                self?.currentSort = sort
                self?.sortButton.setTitle("\(sort.displayName) ▾", for: .normal)
            })
            .disposed(by: disposeBag)

            // SearchBar 바인딩
        searchBar.rx.text.orEmpty
            .bind(to: searchTextRelay)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .withLatestFrom(searchTextRelay)
            .bind(to: searchTriggerRelay)
            .disposed(by: disposeBag)

        searchBar.rx.cancelButtonClicked
            .bind(to: clearTriggerRelay)
            .disposed(by: disposeBag)

            // 필터 버튼
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
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

        // MARK: - Layout 전환

    private func updateLayout(for state: SearchState) {
        switch state {
            case .initial:
                tableView.isHidden = false
                resultHeaderView.isHidden = true
                brandSectionLabel.isHidden = true
                brandTableView.isHidden = true
                perfumeCollectionView.isHidden = true
                emptyView.isHidden = true
                searchBar.showsCancelButton = false
                recentTitleLabel.isHidden = false
                tableView.tableHeaderView = recentHeaderView
                tableView.reloadData()

            case .suggesting:
                tableView.isHidden = false
                resultHeaderView.isHidden = true
                brandSectionLabel.isHidden = true
                brandTableView.isHidden = true
                perfumeCollectionView.isHidden = true
                emptyView.isHidden = true
                searchBar.showsCancelButton = false
                tableView.tableHeaderView = nil
                tableView.reloadData()

            case .result:
                tableView.isHidden = true
                resultHeaderView.isHidden = false
                searchBar.showsCancelButton = false
                searchBar.endEditing(true)
                updateResultVisibility()
        }
    }

        // MARK: - 필터 바텀시트

    private func presentFilterSheet() {
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

        // MARK: - 정렬 액션시트

    private func presentSortActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        SortOption.allCases.forEach { option in
            let action = UIAlertAction(title: option.displayName, style: .default) { [weak self] _ in
                self?.sortChangedRelay.accept(option)
            }
            if option == currentSort {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func updateResultVisibility() {
        guard case let .result(query) = currentState else { return }

        let hasBrands = !brandResults.isEmpty
        let hasPerfumes = !filteredPerfumeResults.isEmpty

        resultHeaderView.isHidden = false
        brandSectionLabel.isHidden = !hasBrands
        brandTableView.isHidden = !hasBrands
        perfumeCollectionView.isHidden = !hasPerfumes

        if !hasPerfumes {
            emptyView.configure(query: query)
            emptyView.isHidden = false
        } else {
            emptyView.isHidden = true
        }

        applyKeyboardInset()
    }

    private func bindKeyboard() {
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
        collectionRepository.fetchCollection()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.likedPerfumeIDs = Set(items.map(\.id))
                self?.perfumeCollectionView.reloadData()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    private func saveLikedPerfume(_ perfume: Perfume) {
        guard !likedPerfumeIDs.contains(perfume.id) else { return }

        collectionRepository.saveCollectedPerfume(perfume, memo: nil)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.insert(perfume.id)
                self?.perfumeCollectionView.reloadData()
            }, onError: { [weak self] _ in
                self?.presentSaveFailureAlert()
            })
            .disposed(by: disposeBag)
    }

    private func deleteLikedPerfume(id: String) {
        guard likedPerfumeIDs.contains(id) else { return }

        collectionRepository.deleteCollectedPerfume(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.likedPerfumeIDs.remove(id)
                self?.perfumeCollectionView.reloadData()
            }, onError: { [weak self] _ in
                self?.presentSaveFailureAlert()
            })
            .disposed(by: disposeBag)
    }

    private func presentSaveFailureAlert() {
        let alert = UIAlertController(title: nil, message: "LIKE 향수 저장에 실패했어요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

    // MARK: - UITableViewDataSource & Delegate

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == brandTableView {
            return brandResults.count
        }
        switch currentState {
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
                cell.textLabel?.text = "최근 검색어가 없어요"
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
        cell.configure(with: perfume, isLiked: likedPerfumeIDs.contains(perfume.id))

            // 찜하기 버튼
        cell.wishlistButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.likedPerfumeIDs.contains(perfume.id) {
                    self.deleteLikedPerfume(id: perfume.id)
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
        label.text = "\"\(query)\"에 대한 검색 결과가 없어요"
    }
}
