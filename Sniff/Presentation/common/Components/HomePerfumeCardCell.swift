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
import Then
import RxSwift

final class HomePerfumeCardCell: UICollectionViewCell {

    static let reuseIdentifier = "HomePerfumeCardCell"
    var disposeBag = DisposeBag()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor
        view.clipsToBounds = true
        return view
    }()

    private let bottleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private let tastingBadgeLabel: PaddingLabel = {
        let label = PaddingLabel(insets: UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6))
        label.text = "시향 기록"
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(red: 0.47, green: 0.39, blue: 0.31, alpha: 1)
        label.backgroundColor = UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1)
        label.layer.cornerCurve = .continuous
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1.0
        label.layer.borderColor = UIColor(red: 0.80, green: 0.75, blue: 0.68, alpha: 1).cgColor
        return label
    }()

    let wishlistButton = UIButton(type: .custom).then {
        PerfumeHeartStyle.configure($0)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let heartImage = UIImage(systemName: "heart.fill", withConfiguration: symbolConfig)?
            .withRenderingMode(.alwaysTemplate)
        if #available(iOS 15.0, *) {
            $0.configuration?.image = heartImage
        } else {
            $0.setImage(heartImage, for: .normal)
            $0.setImage(heartImage, for: .selected)
        }
        $0.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        $0.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .selected)
        PerfumeHeartStyle.applyState(to: $0, isLiked: false)
    }

    private let placeholderCapView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        return view
    }()

    private let placeholderBottleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        view.layer.cornerRadius = 20
        return view
    }()

    private let placeholderMonogramLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let placeholderMessageLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.UIKitScreens.PerfumeDetail.imagePlaceholder
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = UIColor(red: 0.55, green: 0.48, blue: 0.40, alpha: 1)
        return label
    }()

    private let brandLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let perfumeNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let accordsWrapView = HomeAccordWrapView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        tastingBadgeLabel.layer.cornerRadius = 4
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        wishlistButton.isSelected = false
        bottleImageView.kf.cancelDownloadTask()
        bottleImageView.image = nil
        tastingBadgeLabel.isHidden = true
        accordsWrapView.configure(accords: [])
        showPlaceholder()
    }

    private func setup() {
        contentView.backgroundColor = .clear

        // cardView = 이미지 카드 영역 (정사각형)
        contentView.addSubview(cardView)
        // 텍스트는 카드 아래 (cardView 바깥)
        contentView.addSubview(brandLabel)
        contentView.addSubview(perfumeNameLabel)
        contentView.addSubview(accordsWrapView)

        cardView.addSubview(imageContainerView)
        imageContainerView.addSubview(placeholderCapView)
        imageContainerView.addSubview(placeholderBottleView)
        placeholderBottleView.addSubview(placeholderMonogramLabel)
        imageContainerView.addSubview(placeholderMessageLabel)
        imageContainerView.addSubview(bottleImageView)
        imageContainerView.addSubview(wishlistButton)
        cardView.addSubview(tastingBadgeLabel)

        // cardView: 정사각형 이미지 카드
        cardView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(132)
        }

        // 이미지 컨테이너가 카드 전체를 채움
        imageContainerView.snp.makeConstraints {
        $0.edges.equalToSuperview()
        }

        bottleImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }

        tastingBadgeLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(8)
        }

        wishlistButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview()
            $0.size.equalTo(40)
        }

        placeholderCapView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(18)
            $0.size.equalTo(CGSize(width: 18, height: 8))
        }

        placeholderBottleView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 80, height: 80))
        }

        placeholderMonogramLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        placeholderMessageLabel.snp.makeConstraints {
            $0.top.equalTo(placeholderBottleView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(8)
            $0.trailing.lessThanOrEqualToSuperview().offset(-8)
        }

        // 텍스트 영역: 카드 아래
        brandLabel.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(16)
        }

        perfumeNameLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }

       accordsWrapView.snp.makeConstraints {
   
         $0.top.equalTo(perfumeNameLabel.snp.bottom).offset(8)
         $0.leading.trailing.equalToSuperview()
         $0.bottom.lessThanOrEqualToSuperview()
       }
    }

    func configure(with item: HomePerfumeItem, isLiked: Bool = false, hasTastingRecord: Bool? = nil) {
        brandLabel.text = PerfumePresentationSupport.displayBrand(item.brandName)
        perfumeNameLabel.text = PerfumePresentationSupport.displayPerfumeName(item.perfumeName)
        PerfumeHeartStyle.applyState(to: wishlistButton, isLiked: isLiked)
        tastingBadgeLabel.isHidden = !(hasTastingRecord ?? item.hasTastingRecord)

        let monogram = String(item.brandName.prefix(1)).uppercased()
        placeholderMonogramLabel.text = monogram

        imageContainerView.backgroundColor = .systemBackground
        placeholderCapView.backgroundColor = UIColor(red: 0.86, green: 0.83, blue: 0.79, alpha: 1)
        placeholderMonogramLabel.textColor = UIColor(red: 0.55, green: 0.48, blue: 0.40, alpha: 1)

        let accords = item.accordsText
            .components(separatedBy: "  ")
            .map { $0.replacingOccurrences(of: "• ", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { PerfumePresentationSupport.displayAccord($0) }

        accordsWrapView.configure(accords: accords)

        if let urlString = item.imageURL, let url = URL(string: urlString) {
            showLoadingState()
            bottleImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.25)), .cacheOriginalImage]
            ) { [weak self] result in
                switch result {
                case .success:
                    self?.showImage()
                case .failure:
                    self?.showPlaceholder()
                }
            }
        } else {
            showPlaceholder()
        }
    }

    fileprivate static func makeAccordView(_ text: String) -> UIView {
        let displayText = PerfumePresentationSupport.displayAccord(text)

        let dotView = UIView()
        dotView.backgroundColor = ScentFamilyColor.color(for: text)
        dotView.layer.cornerRadius = 4

        let label = UILabel()
        label.text = displayText
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [dotView, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4

        dotView.snp.makeConstraints {
            $0.size.equalTo(8).priority(.high)
        }
        return stack
    }

    private func showImage() {
        bottleImageView.isHidden = false
        placeholderBottleView.isHidden = true
        placeholderCapView.isHidden = true
        placeholderMessageLabel.isHidden = true
    }

    private func showPlaceholder() {
        bottleImageView.isHidden = true
        bottleImageView.image = nil
        placeholderBottleView.isHidden = false
        placeholderCapView.isHidden = false
        placeholderMessageLabel.isHidden = false
    }

    private func showLoadingState() {
        bottleImageView.isHidden = true
        placeholderBottleView.isHidden = false
        placeholderCapView.isHidden = false
        placeholderMessageLabel.isHidden = false
    }
}

private final class HomeAccordWrapView: UIView {
    private var accordViews: [UIView] = []
    private let horizontalSpacing: CGFloat = 6
    private let verticalSpacing: CGFloat = 6
    private let pillHeight: CGFloat = 18

    func configure(accords: [String]) {
        accordViews.forEach { $0.removeFromSuperview() }
        accordViews = accords.map { accord in
            let view = HomePerfumeCardCell.makeAccordView(accord)
            addSubview(view)
            return view
        }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var x: CGFloat = 0
        var y: CGFloat = 0

        for pill in accordViews {
            let width = pill.systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width, height: pillHeight)
            ).width

            if x + width > bounds.width && x > 0 {
                x = 0
                y += pillHeight + verticalSpacing
            }

            pill.frame = CGRect(x: x, y: y, width: width, height: pillHeight)
            x += width + horizontalSpacing
        }
    }

    override var intrinsicContentSize: CGSize {
        guard bounds.width > 0 else {
            let estimatedRows = accordViews.isEmpty ? 0 : 1
            return CGSize(width: UIView.noIntrinsicMetric, height: CGFloat(estimatedRows) * pillHeight)
        }

        var x: CGFloat = 0
        var y: CGFloat = 0

        for pill in accordViews {
            let width = pill.systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width, height: pillHeight)
            ).width

            if x + width > bounds.width && x > 0 {
                x = 0
                y += pillHeight + verticalSpacing
            }

            x += width + horizontalSpacing
        }

        return CGSize(width: UIView.noIntrinsicMetric, height: accordViews.isEmpty ? 0 : y + pillHeight)
    }
}

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
