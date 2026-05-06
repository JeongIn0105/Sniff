//
//  SearchStyle.swift
//  Sniff
//

import UIKit

enum SearchStyle {
    static let neutral950 = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
    static let neutral400 = UIColor(red: 0.69, green: 0.69, blue: 0.69, alpha: 1)
    static let searchBackground = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
    static let clearButtonEditingBackground = UIColor.black.withAlphaComponent(0.5)
    static let clearButtonResultBackground = UIColor(red: 0.74, green: 0.74, blue: 0.74, alpha: 0.5)

    static func pretendard(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let preferredName: String
        switch weight {
        case .semibold:
            preferredName = "Pretendard-SemiBold"
        case .medium:
            preferredName = "Pretendard-Medium"
        case .bold, .heavy, .black:
            preferredName = "Pretendard-Bold"
        default:
            preferredName = "Pretendard-Regular"
        }

        return UIFont(name: preferredName, size: size)
            ?? UIFont(name: "Pretendard-Medium", size: size)
            ?? UIFont(name: "Pretendard", size: size)
            ?? .systemFont(ofSize: size, weight: weight)
    }

    static func searchIconImage(color: UIColor = .black) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale

        return UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24), format: format).image { _ in
            let path = UIBezierPath()
            path.lineWidth = 3
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            color.setStroke()
            UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 13.5, height: 13.5)).stroke()
            path.move(to: CGPoint(x: 14.5, y: 14.5))
            path.addLine(to: CGPoint(x: 21, y: 21))
            path.stroke()
        }.withRenderingMode(.alwaysOriginal)
    }
}
