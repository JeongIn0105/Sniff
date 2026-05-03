//
//  SortBottomSheetViewController.swift
//  Sniff
//

import UIKit
import SnapKit

final class SortBottomSheetViewController: UIViewController {
    // MARK: - Layout 상수 (Figma Dev Mode 역산값)
    // 시트 전체: 390×262pt / 첫 항목 상단 24pt / 마지막 항목 하단 14pt / 텍스트 leading 26pt
    private enum Layout {
        /// 시트 view 상단 ~ 첫 번째 행 상단
        static let topInset: CGFloat = 24
        /// 텍스트 leading 여백 (Figma photo3: 26pt)
        static let leadingInset: CGFloat = 26
        /// trailing 여백
        static let trailingInset: CGFloat = 24
        /// 고정 detent 262pt에서 top 24pt, bottom 14pt가 나오도록 4개 행을 구성
        static let rowHeight: CGFloat = 48
        /// 행 사이 여백: 행 높이로 간격을 만들어 0으로 설정
        static let rowSpacing: CGFloat = 0
        /// 스택 하단 ~ safe area 간격 (홈 인디케이터 영역 위 여백)
        static let bottomInset: CGFloat = 14
    }

    private let currentSort: SortOption
    private let onSelect: (SortOption) -> Void

    // 텍스트 색상: Atomic/Neutral/950
    private let textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)

    init(currentSort: SortOption, onSelect: @escaping (SortOption) -> Void) {
        self.currentSort = currentSort
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Layout.rowSpacing
        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.topInset)
            $0.leading.equalToSuperview().offset(Layout.leadingInset)
            $0.trailing.equalToSuperview().inset(Layout.trailingInset)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(Layout.bottomInset)
        }

        // Figma 와이어프레임 순서: 추천순 → 최신순 → 이름 순 → 이름 역순
        [SortOption.recommended, .latest, .nameAsc, .nameDesc].forEach { option in
            let row = UIControl()
            row.backgroundColor = .clear

            let titleLabel = UILabel()
            titleLabel.text = option.displayName
            titleLabel.textColor = textColor
            titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
            titleLabel.numberOfLines = 1
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = 0.9
            titleLabel.lineBreakMode = .byClipping

            let checkImageView = UIImageView()
            checkImageView.tintColor = textColor
            checkImageView.contentMode = .scaleAspectFit
            checkImageView.image = UIImage(
                systemName: "checkmark",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            )
            checkImageView.isHidden = option != currentSort

            row.addSubview(titleLabel)
            row.addSubview(checkImageView)
            row.snp.makeConstraints {
                $0.height.equalTo(Layout.rowHeight)
            }
            titleLabel.snp.makeConstraints {
                $0.leading.equalToSuperview()
                $0.centerY.equalToSuperview()
                $0.trailing.lessThanOrEqualTo(checkImageView.snp.leading).offset(-12)
            }
            checkImageView.snp.makeConstraints {
                $0.leading.equalTo(titleLabel.snp.trailing).offset(12)
                $0.centerY.equalTo(titleLabel)
                $0.width.height.equalTo(22)
                $0.trailing.lessThanOrEqualToSuperview()
            }

            row.addAction(UIAction { [weak self] _ in
                self?.dismiss(animated: true) {
                    self?.onSelect(option)
                }
            }, for: .touchUpInside)
            stack.addArrangedSubview(row)
        }
    }
}
