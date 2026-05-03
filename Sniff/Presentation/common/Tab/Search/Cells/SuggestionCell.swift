//
//  SuggestionCell.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

    // SuggestionCell.swift
    // 킁킁(Sniff) - 연관 검색어 셀

import UIKit
import SnapKit
import Then
import Kingfisher

final class SuggestionCell: UITableViewCell {

    static let identifier = "SuggestionCell"

        // MARK: - UI Components

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 12
        $0.layer.cornerCurve = .continuous
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1).cgColor
        $0.backgroundColor = .systemGray6
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 2
        $0.lineBreakMode = .byWordWrapping
    }

    private let subTitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1) // Atomic/Neutral/700
        $0.numberOfLines = 1
    }

    private var nameLeadingToThumbnailConstraint: Constraint?
    private var nameLeadingToSuperviewConstraint: Constraint?

        // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground

        [thumbnailImageView, nameLabel, subTitleLabel].forEach {
            contentView.addSubview($0)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            // 셀 높이가 이미지 62pt + 상하 6pt 여백(=74pt) 이상이 되도록 보장
            $0.top.greaterThanOrEqualToSuperview().offset(6)
            $0.bottom.lessThanOrEqualToSuperview().offset(-6)
            $0.size.equalTo(62)
        }

        nameLabel.snp.makeConstraints {
            nameLeadingToThumbnailConstraint = $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12).constraint
            nameLeadingToSuperviewConstraint = $0.leading.equalToSuperview().offset(16).constraint
            // 셀 상단 6pt → 인접 셀 간격 6+6=12pt
            $0.top.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-16)
        }

        subTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            // 셀 하단 6pt → 인접 셀 간격 6+6=12pt
            $0.bottom.equalToSuperview().offset(-6)
        }

        nameLeadingToThumbnailConstraint?.deactivate()
    }

        // MARK: - Configure

    func configure(with item: SuggestionItem, query: String) {
        let displayName: String
        let displaySubtitle: String?

        // SuggestionItem이 imageUrl associated value를 포함하므로 _ 로 무시
        switch item {
        case .brand(let name, _):
            displayName = PerfumePresentationSupport.displayBrand(name)
            displaySubtitle = item.subTitle
        case .perfume(let name, let brand, _):
            displayName = PerfumePresentationSupport.displayPerfumeName(name)
            displaySubtitle = PerfumePresentationSupport.displayBrand(brand)
        }

        nameLabel.text = displayName
        subTitleLabel.text = displaySubtitle

        if case .brand = item {
            // 브랜드: neutral700 색상
            subTitleLabel.textColor = UIColor(red: 0.52, green: 0.52, blue: 0.52, alpha: 1)
        } else {
            // 향수 연관검색어: 브랜드명 표시
            subTitleLabel.textColor = .secondaryLabel
        }

        thumbnailImageView.image = nil
        thumbnailImageView.backgroundColor = .systemGray5
        thumbnailImageView.isHidden = true
        nameLeadingToThumbnailConstraint?.deactivate()
        nameLeadingToSuperviewConstraint?.activate()
    }

    func configure(with item: SuggestionItem, query: String, imageUrl: String?) {
        configure(with: item, query: query)
        if let urlStr = imageUrl, let url = URL(string: urlStr) {
            // 이미지 URL 있으면 항상 썸네일 표시 (브랜드·향수 모두)
            thumbnailImageView.isHidden = false
            nameLeadingToSuperviewConstraint?.deactivate()
            nameLeadingToThumbnailConstraint?.activate()
            thumbnailImageView.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
            thumbnailImageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [.transition(.fade(0.2))]
            )
        } else {
            // URL 없으면 이미지 숨김, leading을 superView 기준으로
            thumbnailImageView.isHidden = true
            nameLeadingToThumbnailConstraint?.deactivate()
            nameLeadingToSuperviewConstraint?.activate()
        }
    }

}
