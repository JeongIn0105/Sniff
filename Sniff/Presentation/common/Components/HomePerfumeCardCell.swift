//
//  HomePerfumeCardCell.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.14.
//


import UIKit
import SnapKit
import Kingfisher

final class HomePerfumeCardCell: UICollectionViewCell {

    static let reuseIdentifier = "HomePerfumeCardCell"

        // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 0.5
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
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

        // 텍스트 영역
    private let brandLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = .tertiaryLabel
        l.numberOfLines = 1
        return l
    }()

    private let perfumeNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.textColor = .label
        l.numberOfLines = 2
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private let accordsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.alignment = .center
        return sv
    }()

        // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

        // MARK: - Setup

    private func setup() {
        contentView.backgroundColor = .clear
        contentView.addSubview(cardView)

        cardView.addSubview(imageContainerView)
        imageContainerView.addSubview(placeholderCapView)
        imageContainerView.addSubview(placeholderBottleView)
        placeholderBottleView.addSubview(placeholderMonogramLabel)
            // 이미지는 플레이스홀더 위에 올라옴
        imageContainerView.addSubview(bottleImageView)

        cardView.addSubview(brandLabel)
        cardView.addSubview(perfumeNameLabel)
        cardView.addSubview(accordsStackView)

        cardView.snp.makeConstraints { $0.edges.equalToSuperview() }

            // 이미지 영역 높이 늘림 (기존 126 → 148)
        imageContainerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(148)
        }

            // 향수 이미지를 이미지 컨테이너 꽉 채우게
        bottleImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        placeholderCapView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(22)
            $0.size.equalTo(CGSize(width: 22, height: 9))
        }
        placeholderBottleView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 78, height: 78))
        }
        placeholderMonogramLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        brandLabel.snp.makeConstraints {
            $0.top.equalTo(imageContainerView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        perfumeNameLabel.snp.makeConstraints {
            $0.top.equalTo(brandLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        accordsStackView.snp.makeConstraints {
            $0.top.equalTo(perfumeNameLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualToSuperview().inset(12)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

        // MARK: - Configure

    func configure(with item: HomePerfumeItem) {
        brandLabel.text = item.brandName
        perfumeNameLabel.text = item.perfumeName

        let monogram = String(item.brandName.prefix(1)).uppercased()
        placeholderMonogramLabel.text = monogram

            // 배경색 단일 크림톤으로 통일
        let creamBg = UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1)
        imageContainerView.backgroundColor = creamBg
        placeholderCapView.backgroundColor = UIColor(red: 0.86, green: 0.83, blue: 0.79, alpha: 1)
        placeholderMonogramLabel.textColor = UIColor(red: 0.55, green: 0.48, blue: 0.40, alpha: 1)

            // accord pills
        accordsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let accords = item.accordsText
            .components(separatedBy: "  ")
            .map { $0.replacingOccurrences(of: "• ", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(2)

        for accord in accords {
            accordsStackView.addArrangedSubview(makePill(accord))
        }

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

    private func makePill(_ text: String) -> UIView {
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

    private func pillColors(for family: String) -> (UIColor, UIColor) {
        switch family {
            case "Floral", "Soft Floral": return (UIColor(hex: "#fbeaf0"), UIColor(hex: "#993556"))
            case "Amber", "Woody Amber":  return (UIColor(hex: "#fdf0e0"), UIColor(hex: "#9a5c12"))
            case "Woody", "Dry Woods", "Mossy Woods": return (UIColor(hex: "#f5ede3"), UIColor(hex: "#7a4f2a"))
            case "Fresh", "Citrus":       return (UIColor(hex: "#e4f5ef"), UIColor(hex: "#1a6b52"))
            case "Water", "Aquatic":      return (UIColor(hex: "#e4eef8"), UIColor(hex: "#1a4a7a"))
            case "Musk":                  return (UIColor(hex: "#eef0f8"), UIColor(hex: "#4a5280"))
            case "Fruity", "Green":       return (UIColor(hex: "#edf5e0"), UIColor(hex: "#3d6b15"))
            default:                      return (UIColor(hex: "#f0ede8"), UIColor(hex: "#6b6560"))
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
    }

    private func showPlaceholder() {
        bottleImageView.isHidden = true
        bottleImageView.image = nil
        placeholderBottleView.isHidden = false
        placeholderCapView.isHidden = false
    }

    private func showLoadingState() {
        bottleImageView.isHidden = true
        placeholderBottleView.isHidden = false
        placeholderCapView.isHidden = false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bottleImageView.kf.cancelDownloadTask()
        bottleImageView.image = nil
        accordsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        showPlaceholder()
    }
}

    // MARK: - UIColor helpers

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    func darker(by amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(s + amount * 0.3, 1), brightness: max(b - amount, 0), alpha: a)
    }
}
