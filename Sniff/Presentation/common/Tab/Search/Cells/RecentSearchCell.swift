//
//  RecentSearchCell.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

import UIKit
import SnapKit
import Then
import RxSwift

final class RecentSearchCell: UITableViewCell {

    static let identifier = "RecentSearchCell"

    var disposeBag = DisposeBag()

    private let clockImageView = UIImageView().then {
        $0.image = UIImage(systemName: "clock")
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
    }

    private let queryLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15)
        $0.textColor = .label
    }

    let deleteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .tertiaryLabel
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        queryLabel.text = nil
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground

        [clockImageView, queryLabel, deleteButton].forEach { contentView.addSubview($0) }

        clockImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(18)
        }

        queryLabel.snp.makeConstraints {
            $0.leading.equalTo(clockImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(deleteButton.snp.leading).offset(-12)
        }

        deleteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
    }

    func configure(with item: RecentSearch) {
        queryLabel.text = item.query
    }
}
