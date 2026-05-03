//
//  SearchViewController+Layout.swift
//  Sniff
//

import UIKit
import SnapKit

extension SearchViewController {

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

        [resultCountLabel, filterButton, sortButton].forEach { resultHeaderView.addSubview($0) }
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
