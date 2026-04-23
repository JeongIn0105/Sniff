//
//  PerfumeGridCell.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.17.
//

    // PerfumeGridCell.swift
    // 킁킁(Sniff) - 향수 그리드 셀

import UIKit
import SnapKit
import Then
import Kingfisher
import RxSwift

final class PerfumeGridCell: UICollectionViewCell {

    static let identifier = "PerfumeGridCell"

    var disposeBag = DisposeBag()

        // MARK: - UI Components

    private let imageContainerView = UIView().then {
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let bottleImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private let placeholderLabel = UILabel().then {
        $0.text = "이미지 준비중입니다"
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    let wishlistButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.setImage(UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate), for: .selected)
        $0.tintColor = .white
        $0.backgroundColor = .clear
    }

    private let brandLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 2
    }

    private let accordStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .leading
    }

        // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        bottleImageView.kf.cancelDownloadTask()
        bottleImageView.image = nil
        placeholderLabel.isHidden = false
        wishlistButton.isSelected = false
        accordStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

        // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground

        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(bottleImageView)
        imageContainerView.addSubview(placeholderLabel)
        imageContainerView.addSubview(wishlistButton)

        [brandLabel, nameLabel, accordStackView].forEach {
            contentView.addSubview($0)
        }

        imageContainerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(imageContainerView.snp.width)
        }

        bottleImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
        }

        placeholderLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        wishlistButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(8)
            $0.size.equalTo(28)
        }

        brandLabel.snp.makeConstraints {
            $0.top.equalTo(imageContainerView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
        }

        accordStackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

        // MARK: - Configure

    func configure(with perfume: Perfume, isLiked: Bool = false) {
        brandLabel.text = perfume.brand
        nameLabel.text = perfume.name
        wishlistButton.isSelected = isLiked
        placeholderLabel.isHidden = false

        if let urlStr = perfume.imageUrl, let url = URL(string: urlStr) {
            bottleImageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [.transition(.fade(0.2))]
            ) { [weak self] result in
                switch result {
                case .success:
                    self?.placeholderLabel.isHidden = true
                case .failure:
                    self?.placeholderLabel.isHidden = false
                }
            }
        }

            // Accord Pill — 최대 2개
        accordStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        perfume.mainAccords.prefix(2).forEach { accord in
            let pill = AccordPillView(accord: accord)
            accordStackView.addArrangedSubview(pill)
        }
    }
}

    // MARK: - AccordPillView

private final class AccordPillView: UIView {

    init(accord: String) {
        super.init(frame: .zero)
        setupUI(accord: accord)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI(accord: String) {
        backgroundColor = .clear

        let dot = UIView().then {
            $0.backgroundColor = ScentFamilyColor.color(for: accord)
            $0.layer.cornerRadius = 4
        }

        let label = UILabel().then {
            $0.text = accord
            $0.font = .systemFont(ofSize: 11)
            $0.textColor = .secondaryLabel
        }

        let stack = UIStackView(arrangedSubviews: [dot, label]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            $0.alignment = .center
        }

        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        dot.snp.makeConstraints { $0.size.equalTo(8) }
    }
}

 
