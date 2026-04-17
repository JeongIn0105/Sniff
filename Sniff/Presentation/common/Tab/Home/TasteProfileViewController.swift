//
//  TasteProfileViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//


import UIKit
import SnapKit

final class TasteProfileViewController: UIViewController {

    private let profileItem: HomeViewModel.HomeProfileItem

    init(profileItem: HomeViewModel.HomeProfileItem) {
        self.profileItem = profileItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "취향 프로필"

            // TasteProfileCardView 삽입 (이미 구현된 카드 컴포넌트)
        let card = TasteProfileCardView()
        view.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        card.configure(
            with: profileItem.profile,
            collectionCount: profileItem.collectionCount,
            tastingCount: profileItem.tastingCount
        )
    }
}
