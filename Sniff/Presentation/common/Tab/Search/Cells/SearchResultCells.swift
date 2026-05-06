//
//  SearchResultCells.swift
//  Sniff
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class BrandResultCell: UITableViewCell {
    static let identifier = "BrandResultCell"

    private let thumbnailContainerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 14
        $0.layer.cornerCurve = .continuous
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(hex: "#E9E5DF").cgColor
        $0.clipsToBounds = true
    }

    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private let brandNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 20, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 1
    }

    private let brandEnglishLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
    }

    func configure(with perfume: Perfume) {
        brandNameLabel.text = PerfumePresentationSupport.displayBrand(perfume.brand)
        brandEnglishLabel.text = perfume.brand.uppercased()

        if let imageUrl = perfume.imageUrl, let url = URL(string: imageUrl) {
            thumbnailImageView.kf.setImage(with: url)
        }
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        [thumbnailContainerView, brandNameLabel, brandEnglishLabel].forEach {
            contentView.addSubview($0)
        }
        thumbnailContainerView.addSubview(thumbnailImageView)

        thumbnailContainerView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(64)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(7)
        }

        brandNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.leading.equalTo(thumbnailContainerView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview()
        }

        brandEnglishLabel.snp.makeConstraints {
            $0.top.equalTo(brandNameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(brandNameLabel)
            $0.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
    }
}

final class PerfumeSearchResultCell: UITableViewCell {
    static let identifier = "PerfumeSearchResultCell"

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

    private let brandLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
        nameLabel.text = nil
        brandLabel.text = nil
    }

    func configure(with perfume: Perfume) {
        nameLabel.text = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        brandLabel.text = PerfumePresentationSupport.displayBrand(perfume.brand)

        if let imageUrl = perfume.imageUrl, let url = URL(string: imageUrl) {
            thumbnailImageView.kf.setImage(with: url)
        }
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground

        [thumbnailImageView, nameLabel, brandLabel].forEach {
            contentView.addSubview($0)
        }

        thumbnailImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(6)
            $0.bottom.lessThanOrEqualToSuperview().offset(-6)
            $0.size.equalTo(62)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(6)
            $0.trailing.equalToSuperview().offset(-16)
        }

        brandLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-6)
        }
    }
}

final class SearchMessageCell: UITableViewCell {
    static let identifier = "SearchMessageCell"

    private let messageLabel = UILabel().then {
        $0.font = UIFont(name: "Pretendard-Medium", size: 16)
            ?? UIFont(name: "Pretendard", size: 16)
            ?? .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1)
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }

    private var topConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(message: String, topInset: CGFloat) {
        messageLabel.text = message
        topConstraint?.update(offset: topInset)
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        contentView.addSubview(messageLabel)

        messageLabel.snp.makeConstraints {
            topConstraint = $0.top.equalToSuperview().offset(40).constraint
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
