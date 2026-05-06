//
//  SearchViewController+TableView.swift
//  Sniff
//

import UIKit
import RxSwift
import RxCocoa

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
            if !isAutoSaveEnabled { return 1 }
            return recentSearches.isEmpty ? 1 : recentSearches.count
        case .suggesting:
            return suggestions.count
        case .result:
            return mode == .register ? filteredPerfumeResults.count : 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == brandTableView {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: BrandResultCell.identifier,
                for: indexPath
            ) as! BrandResultCell
            let brand = brandResults[indexPath.row]
            cell.configure(with: brand)
            return cell
        }

        if case .initial = currentState {
            if !isAutoSaveEnabled || recentSearches.isEmpty {
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
            let recentSearch = recentSearches[indexPath.row]
            cell.configure(with: recentSearch)

            cell.deleteButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.deleteRecentSearchRelay.accept(recentSearch.query)
                })
                .disposed(by: cell.disposeBag)

            return cell
        }

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

        if tableView == brandTableView {
            guard brandResults.indices.contains(indexPath.row) else { return }
            let brand = brandResults[indexPath.row]
            let query = PerfumePresentationSupport.displayBrand(brand.brand)
            searchBar.text = query
            searchTextRelay.accept(query)
            updateSearchBarAccessory(for: query)
            searchTriggerRelay.accept(query)
            return
        }

        if case .initial = currentState, isAutoSaveEnabled, !recentSearches.isEmpty {
            guard mode != .register else { return }
            guard recentSearches.indices.contains(indexPath.row) else { return }
            let query = recentSearches[indexPath.row].query
            searchBar.text = query
            searchTextRelay.accept(query)
            updateSearchBarAccessory(for: query)
            recentSearchTapRelay.accept(query)
            return
        }

        if case .suggesting = currentState {
            guard suggestions.indices.contains(indexPath.row) else { return }
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
            guard filteredPerfumeResults.indices.contains(indexPath.row) else { return }
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

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if case .initial = currentState {
            if !isAutoSaveEnabled || recentSearches.isEmpty {
                return false
            }
        }
        return true
    }
}
