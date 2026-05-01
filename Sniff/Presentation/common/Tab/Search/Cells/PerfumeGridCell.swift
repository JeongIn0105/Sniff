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
    $0.backgroundColor = .systemBackground
    $0.layer.cornerRadius = 16
    $0.layer.cornerCurve = .continuous
    $0.layer.borderWidth = 1
    $0.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor
    $0.clipsToBounds = true
}

    private let bottleImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }

    private let placeholderLabel = UILabel().then {
        $0.text = AppStrings.UIKitScreens.PerfumeDetail.imagePlaceholder
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private let tastingBadgeLabel: PaddingLabel = {
        let label = PaddingLabel(insets: UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6))
        label.text = "시향 기록"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(red: 0.47, green: 0.39, blue: 0.31, alpha: 1)
        label.backgroundColor = UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1)
        label.layer.cornerRadius = 4
        label.layer.cornerCurve = .continuous
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1.0
        label.layer.borderColor = UIColor(red: 0.80, green: 0.75, blue: 0.68, alpha: 1).cgColor
        label.isHidden = true
        return label
    }()

    let wishlistButton = UIButton(type: .custom).then {
        PerfumeHeartStyle.configure($0)
        PerfumeHeartStyle.applyState(to: $0, isLiked: false)
    }

    private let brandLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
    }

   private let nameLabel = UILabel().then {
    $0.font = .systemFont(ofSize: 15, weight: .medium)
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
        tastingBadgeLabel.isHidden = true
    }

        // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground

        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(bottleImageView)
        imageContainerView.addSubview(placeholderLabel)
        imageContainerView.addSubview(wishlistButton)
        imageContainerView.addSubview(tastingBadgeLabel)

        [brandLabel, nameLabel, accordStackView].forEach {
            contentView.addSubview($0)
        }

        imageContainerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(imageContainerView.snp.width)
        }

        bottleImageView.snp.makeConstraints {
    $0.edges.equalToSuperview().inset(18)
}
        placeholderLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        wishlistButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(10)
            $0.size.equalTo(32)
        }

        tastingBadgeLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(8)
        }

        brandLabel.snp.makeConstraints {
            $0.top.equalTo(imageContainerView.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(7)
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

    func configure(with perfume: Perfume, isLiked: Bool = false, hasTastingRecord: Bool = false) {
        brandLabel.text = PerfumePresentationSupport.displayBrand(perfume.brand)
        nameLabel.text = PerfumePresentationSupport.displayPerfumeName(perfume.name)
        PerfumeHeartStyle.applyState(to: wishlistButton, isLiked: isLiked)
        tastingBadgeLabel.isHidden = !hasTastingRecord
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
            let pill = AccordPillView(accord: PerfumePresentationSupport.displayAccord(accord))
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
        let displayAccord = PerfumePresentationSupport.displayAccord(accord)

        let dot = UIView().then {
            $0.backgroundColor = ScentFamilyColor.color(for: accord)
            $0.layer.cornerRadius = 4
        }

        let label = UILabel().then {
            $0.text = displayAccord
            $0.font = .systemFont(ofSize: 13, weight: .medium)
            $0.textColor = .secondaryLabel
            $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }

        [dot, label].forEach { addSubview($0) }

        dot.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(8)
        }

        label.snp.makeConstraints {
            $0.leading.equalTo(dot.snp.trailing).offset(4)
            $0.top.bottom.trailing.equalToSuperview()
        }
    }
}

// MARK: - PaddingLabel

private final class PaddingLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
