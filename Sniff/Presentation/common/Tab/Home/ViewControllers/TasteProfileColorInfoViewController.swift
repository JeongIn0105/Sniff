//
//  TasteProfileColorInfoViewController.swift
//  Sniff
//

import UIKit
import SnapKit
import Then

final class TasteProfileColorInfoViewController: UIViewController {

    // MARK: - 취향 프로필 프리셋 (Figma Dev Mode 정확한 그라디언트 색상)
    struct ProfilePreset {
        let title: String
        let subtitle: String
        let gradientColors: [UIColor]      // [center, mid, edge] 순서
        let gradientLocations: [NSNumber]  // CAGradientLayer.locations 값
    }

    private static let presets: [ProfilePreset] = [
        // 1. 상큼하고 활기찬 취향
        .init(
            title: "상큼하고 활기찬 취향",
            subtitle: "시트러스 · 프루티 중심",
            gradientColors: [
                UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1),
                UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        ),
        // 2. 맑고 세련된 취향
        .init(
            title: "맑고 세련된 취향",
            subtitle: "워터 · 아로마틱 · 시트러스 중심",
            gradientColors: [
                UIColor(red: 0.97, green: 0.94, blue: 0.80, alpha: 1),
                UIColor(red: 0.73, green: 0.87, blue: 0.92, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.52, 1.00]
        ),
        // 3. 시원하고 신비로운 취향
        .init(
            title: "시원하고 신비로운 취향",
            subtitle: "워터 · 아로마틱 중심",
            gradientColors: [
                UIColor(red: 0.80, green: 0.75, blue: 0.83, alpha: 1),
                UIColor(red: 0.60, green: 0.81, blue: 0.89, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        ),
        // 4. 부드럽고 청순한 취향
        .init(
            title: "부드럽고 청순한 취향",
            subtitle: "소프트 플로럴 · 플로럴 · 워터 중심",
            gradientColors: [
                UIColor(red: 1.00, green: 0.56, blue: 0.53, alpha: 1),
                UIColor(red: 0.94, green: 0.66, blue: 0.72, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        ),
        // 5. 포근하고 여유로운 취향
        .init(
            title: "포근하고 여유로운 취향",
            subtitle: "소프트 앰버 · 소프트 플로럴 · 우디 중심",
            gradientColors: [
                UIColor(red: 0.94, green: 0.66, blue: 0.72, alpha: 1),
                UIColor(red: 0.82, green: 0.45, blue: 0.67, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        ),
        // 6. 달콤하고 화사한 취향
        .init(
            title: "달콤하고 화사한 취향",
            subtitle: "프루티 · 플로럴 앰버 · 앰버 중심",
            gradientColors: [
                UIColor(red: 0.94, green: 0.48, blue: 0.75, alpha: 1),
                UIColor(red: 1.00, green: 0.67, blue: 0.49, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        ),
        // 7. 싱그럽고 자연스러운 취향
        .init(
            title: "싱그럽고 자연스러운 취향",
            subtitle: "그린 · 모시 우즈 · 워터 중심",
            gradientColors: [
                UIColor(red: 0.60, green: 0.81, blue: 0.89, alpha: 1),
                UIColor(red: 0.74, green: 0.87, blue: 0.66, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        ),
        // 8. 짙고 시크한 취향
        .init(
            title: "짙고 시크한 취향",
            subtitle: "우디 · 드라이 우즈 · 우디 앰버 중심",
            gradientColors: [
                UIColor(red: 0.75, green: 0.74, blue: 0.65, alpha: 1),
                UIColor(red: 0.84, green: 0.73, blue: 0.59, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        ),
        // 9. 짙고 강렬한 취향
        .init(
            title: "짙고 강렬한 취향",
            subtitle: "앰버 · 우디 앰버 중심",
            gradientColors: [
                UIColor(red: 0.84, green: 0.65, blue: 0.52, alpha: 1),
                UIColor(red: 0.75, green: 0.36, blue: 0.47, alpha: 1),
                UIColor(red: 0.95, green: 0.91, blue: 0.87, alpha: 1)
            ],
            gradientLocations: [0.20, 0.45, 1.00]
        )
    ]

    // MARK: - 색상 상수 (Figma Atomic/Neutral 토큰)
    /// Atomic/Neutral/950 — 거의 검정에 가까운 텍스트 색상
    private static let neutral950 = UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1)
    /// Atomic/Neutral/700 — 중간 회색 텍스트 색상
    private static let neutral700 = UIColor(red: 0.443, green: 0.443, blue: 0.443, alpha: 1)

    // MARK: - UI Components

    private let scrollView = UIScrollView()

    private let contentStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 28 // 와이어프레임 아이템 간격
    }

    private let headerLabel = UILabel().then {
        $0.text = "취향 프로필(홈 색상) 정보"
        $0.font = .systemFont(ofSize: 22, weight: .semibold)
        $0.textColor = TasteProfileColorInfoViewController.neutral950
        $0.numberOfLines = 0
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .label
    }

    // 첫 번째 설명 레이블
    private let desc1Label = UILabel().then {
        $0.text = "*취향 프로필은 총 9종류로, 각각의 취향 프로필은 가장 두드러지는 향 계열을 바탕으로 색상이 결정됩니다."
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = TasteProfileColorInfoViewController.neutral700
        $0.numberOfLines = 0
    }

    // 두 번째 설명 레이블 (첫 번째와 8pt 간격)
    private let desc2Label = UILabel().then {
        $0.text = "*취향 프로필은 보유 향수와 시향기록이 쌓여지는 것에 따라 변경될 수 있습니다. 같은 취향 프로필 안에서도 중심 향 계열은 달라질 수 있으며, 색상은 취향 프로필 기준으로 유지될 수 있습니다."
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = TasteProfileColorInfoViewController.neutral700
        $0.numberOfLines = 0
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - Private Setup

private extension TasteProfileColorInfoViewController {

    func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(headerLabel)
        view.addSubview(closeButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // 드래그 인디케이터 막대와 타이틀 사이에 와이어프레임 기준 여백을 확보합니다.
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
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

        // 설명 영역: 두 레이블을 8pt 간격 VStack으로 묶음
        let descStack = UIStackView(arrangedSubviews: [desc1Label, desc2Label])
        descStack.axis = .vertical
        descStack.spacing = 8
        contentStack.addArrangedSubview(descStack)

        // 프로필 행 추가
        for preset in Self.presets {
            contentStack.addArrangedSubview(makeProfileRow(preset: preset))
        }
    }

    func makeProfileRow(preset: ProfilePreset) -> UIView {
        // 그라디언트 아이콘 (Figma Dev Mode 정확한 색상으로 설정)
        let icon = TasteProfileGradientIconView()
        icon.configure(exactColors: preset.gradientColors, locations: preset.gradientLocations)
        icon.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 44, height: 44))
        }

        // 취향명: size 16, medium, Neutral/950
        let titleLabel = UILabel()
        titleLabel.text = preset.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = TasteProfileColorInfoViewController.neutral950

        // 향 계열: size 12, medium, Neutral/700
        let subtitleLabel = UILabel()
        subtitleLabel.text = preset.subtitle
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        subtitleLabel.textColor = TasteProfileColorInfoViewController.neutral700

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [icon, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 14

        return row
    }
}
