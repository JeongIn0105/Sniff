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

        // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.08).cgColor
        return v
    }()

        // 이미지 영역 — 향수 이미지를 최대한 크게
    private let imageContainerView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        return v
    }()

    private let bottleImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    let wishlistButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(systemName: "heart")?.withRenderingMode(.alwaysTemplate), for: .normal)
        $0.setImage(UIImage(systemName: "heart.fill")?.withRenderingMode(.alwaysTemplate), for: .selected)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.18)
        $0.layer.cornerRadius = 14
    }

        // 플레이스홀더 — 이미지 없을 때만
    private let placeholderCapView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5
        return v
    }()

    private let placeholderBottleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        v.layer.cornerRadius = 20
        return v
    }()

    private let placeholderMonogramLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 24, weight: .bold)
        l.textAlignment = .center
        return l
    }()

    private let placeholderMessageLabel: UILabel = {
        let l = UILabel()
        l.text = AppStrings.UIKitScreens.PerfumeDetail.imagePlaceholder
        l.font = .systemFont(ofSize: 11, weight: .medium)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.textColor = UIColor(red: 0.55, green: 0.48, blue: 0.40, alpha: 1)
        return l
    }()

        // 텍스트 영역
    private let brandLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        return l
    }()

    private let perfumeNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .medium)
        l.textColor = .label
        l.numberOfLines = 2
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let accordsWrapView = HomeAccordWrapView()

        // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        wishlistButton.isSelected = false
        bottleImageView.kf.cancelDownloadTask()
        bottleImageView.image = nil
        accordsWrapView.configure(accords: [])
        showPlaceholder()
    }

        // MARK: - Setup

    private func setup() {
        contentView.backgroundColor = .clear
        contentView.addSubview(cardView)

        cardView.addSubview(imageContainerView)
        imageContainerView.addSubview(placeholderCapView)
        imageContainerView.addSubview(placeholderBottleView)
        placeholderBottleView.addSubview(placeholderMonogramLabel)
        imageContainerView.addSubview(placeholderMessageLabel)
            // 이미지는 플레이스홀더 위에 올라옴
        imageContainerView.addSubview(bottleImageView)
        imageContainerView.addSubview(wishlistButton)

        cardView.addSubview(brandLabel)
        cardView.addSubview(perfumeNameLabel)
        cardView.addSubview(accordsWrapView)

        cardView.snp.makeConstraints { $0.edges.equalToSuperview() }

        imageContainerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(cardView.snp.width)
        }

        bottleImageView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(10)
        }

        wishlistButton.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(8)
            $0.size.equalTo(28)
        }

        placeholderCapView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(28)
            $0.size.equalTo(CGSize(width: 24, height: 10))
        }
        placeholderBottleView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 96, height: 96))
        }
        placeholderMonogramLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        placeholderMessageLabel.snp.makeConstraints {
            $0.top.equalTo(placeholderBottleView.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(16)
            $0.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        brandLabel.snp.makeConstraints {
            $0.top.equalTo(imageContainerView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(10)
        }
        perfumeNameLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(10)
        }
        accordsWrapView.snp.makeConstraints {
            $0.top.equalTo(perfumeNameLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(10)
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

        // MARK: - Configure

    func configure(with item: HomePerfumeItem, isLiked: Bool = false) {
        brandLabel.text = PerfumePresentationSupport.displayBrand(item.brandName)
        perfumeNameLabel.text = PerfumePresentationSupport.displayPerfumeName(item.perfumeName)
        wishlistButton.isSelected = isLiked

        let monogram = String(item.brandName.prefix(1)).uppercased()
        placeholderMonogramLabel.text = monogram

            // 배경색 단일 크림톤으로 통일
        let creamBg = UIColor(red: 0.97, green: 0.95, blue: 0.92, alpha: 1)
        imageContainerView.backgroundColor = creamBg
        placeholderCapView.backgroundColor = UIColor(red: 0.86, green: 0.83, blue: 0.79, alpha: 1)
        placeholderMonogramLabel.textColor = UIColor(red: 0.55, green: 0.48, blue: 0.40, alpha: 1)

            // accord pills
        let accords = item.accordsText
            .components(separatedBy: "  ")
            .map { $0.replacingOccurrences(of: "• ", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { PerfumePresentationSupport.displayAccord($0) }

        accordsWrapView.configure(accords: accords)


            // 이미지 로드
        if let urlString = item.imageURL, let url = URL(string: urlString) {
            showLoadingState()
            bottleImageView.kf.setImage(
                with: url,
                options: [.transition(.fade(0.25)), .cacheOriginalImage]
            ) { [weak self] result in
                switch result {
                    case .success: self?.showImage()
                    case .failure: self?.showPlaceholder()
                }
            }
        } else {
            showPlaceholder()
        }
    }

        // MARK: - Pill

    fileprivate static func makePill(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .medium)

        let (bg, fg) = pillColors(for: text)
        label.textColor = fg

        let container = UIView()
        container.backgroundColor = bg
        container.layer.cornerRadius = 9
        container.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(3)
            $0.leading.trailing.equalToSuperview().inset(7)
        }
        return container
    }

    fileprivate static func pillColors(for family: String) -> (UIColor, UIColor) {
        switch family {
        case "플로럴", "소프트 플로럴", "플로럴 앰버":
            return (UIColor(hex: "#fbeaf0"), UIColor(hex: "#993556"))
        case "소프트 앰버", "앰버", "우디 앰버":
            return (UIColor(hex: "#fdf0e0"), UIColor(hex: "#9a5c12"))
        case "우즈", "드라이 우즈", "모씨 우즈", "우디":
            return (UIColor(hex: "#f5ede3"), UIColor(hex: "#7a4f2a"))
        case "시트러스", "프레시":
            return (UIColor(hex: "#e4f5ef"), UIColor(hex: "#1a6b52"))
        case "워터", "아쿠아틱":
            return (UIColor(hex: "#e4eef8"), UIColor(hex: "#1a4a7a"))
        case "프루티", "그린":
            return (UIColor(hex: "#edf5e0"), UIColor(hex: "#3d6b15"))
        case "아로마틱", "머스크", "머스키":
            return (UIColor(hex: "#eeeaf8"), UIColor(hex: "#56468b"))
        default:
            return (UIColor(hex: "#f0ede8"), UIColor(hex: "#6b6560"))
        }
    }

    private func placeholderBgColor(for brandName: String) -> UIColor {
        let colors: [UIColor] = [
            UIColor(hex: "#fdf6f9"),
            UIColor(hex: "#fdf4ec"),
            UIColor(hex: "#f4f8fd"),
            UIColor(hex: "#f0f8f4"),
            UIColor(hex: "#fdf8f0"),
        ]
        return colors[abs(brandName.hashValue) % colors.count]
    }

        // MARK: - 상태 전환

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
    private let pillHeight: CGFloat = 24

    func configure(accords: [String]) {
        accordViews.forEach { $0.removeFromSuperview() }
        accordViews = accords.map { accord in
            let pill = HomePerfumeCardCell.makePill(accord)
            addSubview(pill)
            return pill
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

    // MARK: - UIColor helpers

private extension UIColor {
    func darker(by amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(s + amount * 0.3, 1), brightness: max(b - amount, 0), alpha: a)
    }
}
