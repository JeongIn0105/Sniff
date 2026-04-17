    //
    //  HomeQuickActionCell.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.14.
    //

import UIKit
import Combine
import SnapKit

final class HomeQuickActionCell: UICollectionViewCell {

    static let reuseIdentifier = "HomeQuickActionCell"

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor(white: 0.58, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func configure(with item: HomeQuickAction) {
        titleLabel.text = item.title
        iconImageView.image = UIImage(systemName: item.systemImageName)
    }
}
