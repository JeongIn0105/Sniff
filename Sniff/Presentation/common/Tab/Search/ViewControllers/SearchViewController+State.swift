//
//  SearchViewController+State.swift
//  Sniff
//

import UIKit
import SnapKit
import RxSwift

extension SearchViewController {

    // MARK: - Layout State

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
        brandSectionLabel.text = AppStrings.UIKitScreens.Search.brandCount(0)
        brandEmptyLabel.text = AppStrings.UIKitScreens.Search.landingBrandMessage
        resultCountLabel.text = AppStrings.UIKitScreens.Search.perfumeCount(0)
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

    func updateResultVisibility() {
        guard case let .result(query) = currentState else { return }

        let hasBrands = !brandResults.isEmpty
        let hasPerfumes = !filteredPerfumeResults.isEmpty

        resultHeaderView.isHidden = false
        brandSectionLabel.isHidden = false
        brandTableView.isHidden = !hasBrands
        brandEmptyLabel.isHidden = hasBrands
        perfumeCollectionView.isHidden = !hasPerfumes
        brandSectionLabel.text = AppStrings.UIKitScreens.Search.brandCount(brandResults.count)
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

    func applyKeyboardInset() {
        let bottomInset = keyboardInset + 16
        [tableView, brandTableView].forEach {
            $0.contentInset.bottom = bottomInset
            $0.verticalScrollIndicatorInsets.bottom = bottomInset
        }
        perfumeCollectionView.contentInset.bottom = bottomInset
        perfumeCollectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    // MARK: - Likes

    func loadLikedPerfumes() {
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.likedPerfumeIDs = Set(items.map(\.id))
                self?.reloadPerfumeResults()
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    func saveLikedPerfume(_ perfume: Perfume) {
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

    func deleteLikedPerfume(id: String) {
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

    func presentSaveFailure(_ error: Error) {
        if let limitError = error as? CollectionUsageLimitError {
            showAppToast(message: limitError.localizedDescription)
            return
        }

        let alert = UIAlertController(title: nil, message: AppStrings.UIKitScreens.Search.likeSaveFailed, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
        present(alert, animated: true)
    }

    func updateSearchBarLeadingConstraint() {
        let showsBackButton = !backButton.isHidden
        searchBarLeadingToBackConstraint?.isActive = showsBackButton
        searchBarLeadingToSuperviewConstraint?.isActive = !showsBackButton
        view.layoutIfNeeded()
    }
}
