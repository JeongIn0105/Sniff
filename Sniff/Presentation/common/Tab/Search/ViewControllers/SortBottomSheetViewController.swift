//
//  SortBottomSheetViewController.swift
//  Sniff
//

import UIKit
import SnapKit

final class SortBottomSheetViewController: UIViewController {
    private let currentSort: SortOption
    private let onSelect: (SortOption) -> Void

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
        stack.spacing = 0
        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(18)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(24)
        }

        [SortOption.recommended, .nameAsc, .nameDesc].forEach { option in
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = option.displayName
            configuration.baseForegroundColor = .label
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 0, bottom: 18, trailing: 0)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 16, weight: .medium)
                return outgoing
            }
            if option == currentSort {
                configuration.image = UIImage(systemName: "checkmark")
                configuration.imagePlacement = .trailing
                configuration.imagePadding = 12
            }
            button.configuration = configuration
            button.contentHorizontalAlignment = .leading
            button.addAction(UIAction { [weak self] _ in
                self?.dismiss(animated: true) {
                    self?.onSelect(option)
                }
            }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }
}
