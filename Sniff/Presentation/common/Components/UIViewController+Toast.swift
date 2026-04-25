//
//  UIViewController+Toast.swift
//  Sniff
//

import UIKit
import SnapKit

extension UIViewController {
    func showAppToast(message: String, bottomOffset: CGFloat = 36) {
        view.subviews
            .filter { $0.accessibilityIdentifier == "appToastView" }
            .forEach { $0.removeFromSuperview() }

        let container = UIView()
        container.accessibilityIdentifier = "appToastView"
        container.backgroundColor = UIColor.black.withAlphaComponent(0.86)
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2

        container.addSubview(label)
        view.addSubview(container)

        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 13, left: 18, bottom: 13, right: 18))
        }

        container.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-bottomOffset)
        }

        container.alpha = 0
        UIView.animate(withDuration: 0.2) {
            container.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 2.8, options: [.curveEaseInOut]) {
                container.alpha = 0
            } completion: { [weak container] _ in
                container?.removeFromSuperview()
            }
        }
    }
}
