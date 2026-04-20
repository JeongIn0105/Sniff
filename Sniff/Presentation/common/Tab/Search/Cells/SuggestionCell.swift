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
        $0.layer.cornerRadius = 20
        $0.backgroundColor = .systemGray5
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15)
        $0.textColor = .label
    }

        // 매칭된 텍스트 강조용 (브랜드명은 빨간색)
    private let subTitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .systemRed
    }

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
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-20)
        }

        subTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

        // MARK: - Configure

    func configure(with item: SuggestionItem, query: String) {
        nameLabel.attributedText = highlight(text: item.displayName, query: query)
        subTitleLabel.text = item.subTitle

            // 브랜드 타입은 subTitle을 "브랜드"로 고정 (검정색)
        if case .brand = item {
            subTitleLabel.textColor = .secondaryLabel
        } else {
            subTitleLabel.textColor = .systemRed
        }

        thumbnailImageView.image = nil
        thumbnailImageView.backgroundColor = .systemGray5
    }

    func configure(with item: SuggestionItem, query: String, imageUrl: String?) {
        configure(with: item, query: query)
        if let urlStr = imageUrl, let url = URL(string: urlStr) {
            thumbnailImageView.kf.setImage(with: url, placeholder: nil)
        }
    }

        // MARK: - 검색어 하이라이트 (빨간색 강조)
    private func highlight(text: String, query: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let range = (text.lowercased() as NSString).range(of: query.lowercased())
        if range.location != NSNotFound {
            attributed.addAttribute(.foregroundColor, value: UIColor.systemRed, range: range)
        }
        return attributed
    }
}
