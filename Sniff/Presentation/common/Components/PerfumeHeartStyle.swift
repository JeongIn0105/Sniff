//
//  PerfumeHeartStyle.swift
//  Sniff
//

import UIKit
import SwiftUI

enum PerfumeHeartStyle {
    static let activeUIColor = UIColor.black
    static let inactiveUIColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1)
    private static let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)

    static var activeColor: Color { Color(uiColor: activeUIColor) }
    static var inactiveColor: Color { Color(uiColor: inactiveUIColor) }

    static func configure(_ button: UIButton) {
        let heartImage = UIImage(systemName: "heart.fill", withConfiguration: symbolConfig)?
            .withRenderingMode(.alwaysTemplate)

        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.image = heartImage
            configuration.contentInsets = .zero
            configuration.background.backgroundColor = .clear
            configuration.baseForegroundColor = inactiveUIColor
            button.configuration = configuration
        } else {
            button.setImage(heartImage, for: .normal)
            button.setImage(heartImage, for: .selected)
            button.adjustsImageWhenHighlighted = false
        }

        button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .selected)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 0
        button.layer.borderWidth = 0
        button.layer.borderColor = nil
        button.tintColor = inactiveUIColor
        button.imageView?.contentMode = .scaleAspectFit
        button.clipsToBounds = false
        button.alpha = 1
        button.isHidden = false
    }

    static func applyState(to button: UIButton, isLiked: Bool) {
        button.isSelected = isLiked
        let color = isLiked ? activeUIColor : inactiveUIColor
        if #available(iOS 15.0, *) {
            button.configuration?.baseForegroundColor = color
        }
        button.tintColor = color
    }
}
