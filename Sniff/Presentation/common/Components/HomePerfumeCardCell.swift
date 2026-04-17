    //
    //  HomePerfumeCardCell.swift
    //  Sniff
    //
    //  Created by t2025-m0239 on 2026.04.14.
    //

import UIKit
import Combine
import SnapKit
import Kingfisher

final class HomePerfumeCardCell: UICollectionViewCell {

    static let reuseIdentifier = "HomePerfumeCardCell"

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 14
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 18
        return view
    }()

    private let favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .white
        button.isUserInteractionEnabled = false
        return button
    }()

    private let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        view.layer.cornerRadius = 12
        return view
    }()

    private let bottleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(white: 0.82, alpha: 1.0)
        return imageView
    }()

    private let brandLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let perfumeNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let accordLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        contentView.addSubview(cardView)
        cardView.addSubview(imageContainerView)
        imageContainerView.addSubview(bottleImageView)
        cardView.addSubview(favoriteButton)
        cardView.addSubview(brandLabel)
        cardView.addSubview(perfumeNameLabel)
        cardView.addSubview(accordLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        favoriteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.size.equalTo(20)
        }

        imageContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }

        bottleImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 56, height: 88))
        }

        brandLabel.snp.makeConstraints { make in
            make.top.equalTo(imageContainerView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
        }

        perfumeNameLabel.snp.makeConstraints { make in
            make.top.equalTo(brandLabel.snp.bottom).offset(3)
            make.leading.trailing.equalToSuperview()
        }

        accordLabel.snp.makeConstraints { make in
            make.top.equalTo(perfumeNameLabel.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bottleImageView.kf.cancelDownloadTask()
        bottleImageView.image = UIImage(systemName: "photo")
    }

    func configure(with item: HomePerfumeItem) {
        brandLabel.text = item.brandName
        perfumeNameLabel.text = item.perfumeName
        accordLabel.text = item.accordsText

        if let urlString = item.imageURL,
           let url = URL(string: urlString) {
            bottleImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            bottleImageView.image = UIImage(systemName: "photo")
        }
    }
}
