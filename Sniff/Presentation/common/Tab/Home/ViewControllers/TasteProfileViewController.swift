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

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.tintColor = .label
    }

    private let titleLabel = UILabel().then {
        $0.text = AppStrings.Home.tasteProfileTitle
        $0.font = .systemFont(ofSize: 22, weight: .bold)
        $0.textColor = .label
    }

    private let cardView = TasteProfileCardView()

    private let helperContainerView = UIView().then {
        $0.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1)
        $0.layer.cornerRadius = 14
        $0.layer.cornerCurve = .continuous
    }

    private let helperIconView = UIImageView(image: UIImage(systemName: "info.circle")).then {
        $0.tintColor = .tertiaryLabel
        $0.contentMode = .scaleAspectFit
    }

    private let helperLabel = UILabel().then {
        $0.text = "향수를 등록하거나 시향 기록을 남기면 취향이 더 선명해져요"
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    init(profileItem: HomeViewModel.HomeProfileItem) {
        self.profileItem = profileItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureContent()
    }

    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
}

private extension TasteProfileViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [backButton, titleLabel, cardView, helperContainerView].forEach { contentView.addSubview($0) }
        [helperIconView, helperLabel].forEach { helperContainerView.addSubview($0) }

        backButton.addTarget(self, action: #selector(popViewController), for: .touchUpInside)

        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        backButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.leading.equalTo(backButton.snp.trailing).offset(8)
        }

        cardView.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(448)
        }

        helperContainerView.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(20)
        }

        helperIconView.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
            $0.size.equalTo(15)
        }

        helperLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(12)
            $0.leading.equalTo(helperIconView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(12)
        }
    }

    func configureContent() {
        cardView.configure(
            with: profileItem.profile,
            collectionCount: profileItem.collectionCount,
            tastingCount: profileItem.tastingCount
        )
        helperLabel.text = helperText(for: profileItem.profile)
    }

    func helperText(for profile: UserTasteProfile) -> String {
        switch profile.stage {
        case .onboardingOnly:
            return AppStrings.DomainDisplay.TasteProfile.needsCollectionOrRecord
        case .onboardingCollection:
            return AppStrings.DomainDisplay.TasteProfile.needsTastingRecord
        case .earlyTasting, .heavyTasting:
            return "향수를 등록하거나 시향 기록을 남기면 취향이 계속 업데이트돼요"
        }
    }
}
