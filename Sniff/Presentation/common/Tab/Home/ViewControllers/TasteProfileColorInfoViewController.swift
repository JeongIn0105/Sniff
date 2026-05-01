//
//  TasteProfileColorInfoViewController.swift
//  Sniff
//

import UIKit
import SnapKit
import Then

final class TasteProfileColorInfoViewController: UIViewController {

    struct ProfilePreset {
        let title: String
        let subtitle: String
        let families: [String]
    }

    private static let presets: [ProfilePreset] = [
        .init(title: "상큼하고 활기찬 취향", subtitle: "시트러스 · 프루티 중심", families: ["Citrus", "Fruity"]),
        .init(title: "맑고 세련된 취향", subtitle: "워터 · 시트러스 중심", families: ["Water", "Citrus"]),
        .init(title: "시원하고 신비로운 취향", subtitle: "워터 · 아로마틱 중심", families: ["Water", "Aromatic"]),
        .init(title: "부드럽고 청순한 취향", subtitle: "소프트 플로럴 · 플로럴 중심", families: ["Soft Floral", "Floral"]),
        .init(title: "포근하고 여유로운 취향", subtitle: "소프트 앰버 · 소프트 플로럴 중심", families: ["Soft Amber", "Soft Floral"]),
        .init(title: "달콤하고 화사한 취향", subtitle: "프루티 · 플로럴 앰버 중심", families: ["Fruity", "Floral Amber"]),
        .init(title: "싱그럽고 자연스러운 취향", subtitle: "그린 · 워터 중심", families: ["Green", "Water"]),
        .init(title: "짙고 시크한 취향", subtitle: "우디 · 드라이 우즈 중심", families: ["Woods", "Dry Woods"]),
        .init(title: "짙고 강렬한 취향", subtitle: "앰버 · 우디 앰버 중심", families: ["Amber", "Woody Amber"])
    ]

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 24
    }

    private let headerLabel = UILabel().then {
        $0.text = "취향 프로필(홈 색상) 정보"
        $0.font = .systemFont(ofSize: 22, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .label
    }

    private let descriptionLabel = UILabel().then {
        $0.text = "*취향 프로필은 총 9종류로, 각각의 취향 프로필은 가장 두드러지는 향 계열을 바탕으로 색상이 결정됩니다.\n*취향 프로필은 보유 향수와 시향기록이 쌓이는 것에 따라 취향 프로필이 변경될 수 있습니다."
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

private extension TasteProfileColorInfoViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(headerLabel)
        view.addSubview(closeButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        headerLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().inset(24)
            $0.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-12)
        }

        closeButton.snp.makeConstraints {
            $0.centerY.equalTo(headerLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.size.equalTo(28)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(20)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(4)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.width.equalTo(scrollView).inset(24)
            $0.bottom.equalToSuperview().inset(20)
        }

        contentStack.addArrangedSubview(descriptionLabel)

        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(8) }
        contentStack.addArrangedSubview(spacer)

        for preset in Self.presets {
            contentStack.addArrangedSubview(makeProfileRow(preset: preset))
        }
    }

    func makeProfileRow(preset: ProfilePreset) -> UIView {
        let icon = TasteProfileGradientIconView()
        icon.configure(families: preset.families)

        let titleLabel = UILabel()
        titleLabel.text = preset.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = preset.subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [icon, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14

        icon.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 44, height: 44))
        }

        return row
    }
}
