//
//  TasteProfileViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//


import UIKit
import SnapKit
import Then

final class TasteProfileViewController: UIViewController {

    private let profileItem: HomeViewModel.HomeProfileItem

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
    }

    private let titleLabel = UILabel().then {
        $0.text = AppStrings.Home.tasteProfileTitle
        $0.font = .systemFont(ofSize: 18, weight: .semibold)
        $0.textColor = .label
    }

    init(profileItem: HomeViewModel.HomeProfileItem) {
        self.profileItem = profileItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(backButton)
        view.addSubview(titleLabel)

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.centerX.equalToSuperview()
        }

        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)

            // TasteProfileCardView 삽입 (이미 구현된 카드 컴포넌트)
        let card = TasteProfileCardView()
        view.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        card.configure(
            with: profileItem.profile,
            collectionCount: profileItem.collectionCount,
            tastingCount: profileItem.tastingCount
        )
    }

    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
}
