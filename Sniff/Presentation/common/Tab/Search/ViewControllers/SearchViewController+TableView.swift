//
//  SearchViewController+TableView.swift
//  Sniff
//

import UIKit
import RxSwift

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
            return recentSearches.isEmpty ? 1 : recentSearches.count
        case .suggesting:
            return suggestions.count
        case .result:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

        if case .initial = currentState {
            if recentSearches.isEmpty {
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

            cell.deleteButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    guard let self else { return }
                    let query = self.recentSearches[indexPath.row].query
                    self.deleteRecentSearchRelay.accept(query)
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
            cell.configure(with: item, query: searchTextRelay.value)
            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if tableView == brandTableView {
            let brand = brandResults[indexPath.row]
            searchTriggerRelay.accept(brand.brand)
            return
        }

        if case .initial = currentState, !recentSearches.isEmpty {
            recentSearchTapRelay.accept(recentSearches[indexPath.row].query)
            return
        }

        if case .suggesting = currentState {
            let item = suggestions[indexPath.row]
            suggestionTapRelay.accept(item)
            searchBar.text = item.displayName
            searchBar.resignFirstResponder()
            return
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if case .initial = currentState, recentSearches.isEmpty {
            return false
        }
        return true
    }
}
