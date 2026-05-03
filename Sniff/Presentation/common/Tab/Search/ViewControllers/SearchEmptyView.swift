//
//  SearchEmptyView.swift
//  Sniff
//

import UIKit
import SnapKit
import Then

final class SearchEmptyView: UIView {

    private let label = UILabel().then {
        $0.textAlignment = .center
        $0.textColor = .secondaryLabel
        $0.font = .systemFont(ofSize: 15)
        $0.numberOfLines = 0
    }

    init() {
        super.init(frame: .zero)
        addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(query: String) {
        label.text = AppStrings.UIKitScreens.Search.noResults(query)
    }

    func configureLanding() {
        label.text = AppStrings.UIKitScreens.Search.landingPerfumeMessage
    }
}
