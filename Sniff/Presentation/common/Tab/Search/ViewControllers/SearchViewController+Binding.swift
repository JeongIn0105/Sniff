//
//  SearchViewController+Binding.swift
//  Sniff
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

extension SearchViewController {

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
                self.brandSectionLabel.text = AppStrings.UIKitScreens.Search.brandCount(brands.count)
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
                self?.resultCountLabel.text = AppStrings.UIKitScreens.Search.perfumeCount(count)
            })
            .disposed(by: disposeBag)
    }

    func bindActiveFilter(_ activeFilter: Observable<SearchFilter>) {
        activeFilter
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                guard let self else { return }
                self.currentFilter = filter
                let label = filter.summaryLabel.map { "  \($0)" } ?? ""
                let image = UIImage(systemName: "slider.horizontal.3")
                self.filterButton.setTitle(label, for: .normal)
                self.filterButton.setImage(image, for: .normal)
                self.filterButton.backgroundColor = filter.isEmpty ? .systemGray5 : .label
                self.filterButton.tintColor = filter.isEmpty ? .label : .white
                self.filterButton.setTitleColor(filter.isEmpty ? .label : .white, for: .normal)
            })
            .disposed(by: disposeBag)
    }

    func bindCurrentSort(_ currentSort: Observable<SortOption>) {
        currentSort
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] sort in
                self?.currentSort = sort
                self?.sortButton.setTitle("\(sort.displayName) ▾", for: .normal)
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
