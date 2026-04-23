//
//  PerfumeGridCardView.swift
//  Sniff
//

import SwiftUI
import Kingfisher
import UIKit

enum PerfumeCardStyle: Equatable {
    case preview
    case grid
    case listThumbnail

    var defaultCardWidth: CGFloat? {
        switch self {
        case .preview:
            return 124
        case .grid, .listThumbnail:
            return nil
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .preview, .grid:
            return 20
        case .listThumbnail:
            return 18
        }
    }

    var imagePadding: CGFloat {
        switch self {
        case .preview, .grid:
            return 4
        case .listThumbnail:
            return 6
        }
    }

    var innerCanvasInset: CGFloat {
        switch self {
        case .preview:
            return 10
        case .grid:
            return 11
        case .listThumbnail:
            return 11
        }
    }

    var innerCanvasCornerRadius: CGFloat {
        switch self {
        case .preview, .grid:
            return 14
        case .listThumbnail:
            return 12
        }
    }

    var placeholderIconSize: CGFloat {
        switch self {
        case .preview, .grid:
            return 28
        case .listThumbnail:
            return 24
        }
    }

    var contentTopSpacing: CGFloat {
        switch self {
        case .preview, .grid:
            return 10
        case .listThumbnail:
            return 0
        }
    }

    var brandFontSize: CGFloat {
        switch self {
        case .preview, .grid, .listThumbnail:
            return 12
        }
    }

    var brandHeight: CGFloat? {
        switch self {
        case .preview, .grid:
            return 18
        case .listThumbnail:
            return nil
        }
    }

    var nameFontSize: CGFloat {
        switch self {
        case .preview, .grid:
            return 16
        case .listThumbnail:
            return 17
        }
    }

    var nameLineSpacing: CGFloat {
        switch self {
        case .preview, .grid, .listThumbnail:
            return 2
        }
    }

    var brandToNameSpacing: CGFloat {
        switch self {
        case .preview, .grid, .listThumbnail:
            return 5
        }
    }

    var nameToAccordSpacing: CGFloat {
        switch self {
        case .preview, .grid, .listThumbnail:
            return 5
        }
    }

    var textBlockHeight: CGFloat? {
        switch self {
        case .preview:
            return 80
        case .grid:
            return 82
        case .listThumbnail:
            return nil
        }
    }

    var accordSpacing: CGFloat {
        switch self {
        case .preview, .grid, .listThumbnail:
            return 10
        }
    }

    var accordDotSize: CGFloat {
        switch self {
        case .preview, .grid, .listThumbnail:
            return 8
        }
    }

    var accordFontSize: CGFloat {
        switch self {
        case .preview, .grid, .listThumbnail:
            return 12
        }
    }

    var likeIconSize: CGFloat {
        switch self {
        case .preview, .grid:
            return 20
        case .listThumbnail:
            return 18
        }
    }

    var likeIconInset: CGFloat {
        switch self {
        case .preview, .grid:
            return 10
        case .listThumbnail:
            return 8
        }
    }

    var artworkWidthRatio: CGFloat {
        switch self {
        case .preview:
            return 0.84
        case .grid:
            return 0.86
        case .listThumbnail:
            return 0.76
        }
    }

    var artworkHeightRatio: CGFloat {
        switch self {
        case .preview:
            return 0.88
        case .grid:
            return 0.88
        case .listThumbnail:
            return 0.84
        }
    }

    var badgeTopInset: CGFloat {
        switch self {
        case .preview, .grid:
            return 10
        case .listThumbnail:
            return 8
        }
    }

    var badgeLeadingInset: CGFloat {
        switch self {
        case .preview, .grid:
            return 10
        case .listThumbnail:
            return 8
        }
    }

    var badgeHeight: CGFloat {
        switch self {
        case .preview, .grid:
            return 34
        case .listThumbnail:
            return 30
        }
    }

    var usesFixedTextBlockHeight: Bool {
        switch self {
        case .preview, .grid:
            return true
        case .listThumbnail:
            return false
        }
    }
}

enum PerfumeGridCardLayout {
    static let previewCardWidth: CGFloat = 124
    static let previewCardSpacing: CGFloat = 10
    static let previewTrailingPeekInset: CGFloat = 10
    static let gridHorizontalPadding: CGFloat = 20
    static let gridColumnSpacing: CGFloat = 16
    static let gridRowSpacing: CGFloat = 30
    static let listHorizontalPadding: CGFloat = 20
    static let listRowSpacing: CGFloat = 18
    static let listThumbnailSize: CGFloat = 104
    static let cardBackgroundColor = Color(red: 0.978, green: 0.978, blue: 0.985)
}

private let perfumeArtworkBackgroundCleanupProcessor = PerfumeArtworkBackgroundCleanupProcessor()

struct PerfumeGridCardView: View {
    let imageURL: String?
    let brand: String
    let name: String
    let accords: [String]
    let isLiked: Bool
    var style: PerfumeCardStyle = .grid
    var cardWidth: CGFloat? = nil
    var showsHeartIcon: Bool = true
    var hasTastingRecord: Bool = false

    private var resolvedCardWidth: CGFloat? {
        cardWidth ?? style.defaultCardWidth
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection

            PerfumeCardTextContentView(
                brand: brand,
                name: name,
                accords: accords,
                style: style
            )
            .padding(.top, style.contentTopSpacing)
        }
        .frame(width: resolvedCardWidth, alignment: .topLeading)
        .frame(maxWidth: resolvedCardWidth == nil ? .infinity : nil, alignment: .topLeading)
    }

    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            PerfumeCardArtworkView(
                imageURL: imageURL,
                style: style
            )

            if hasTastingRecord {
                Text(AppStrings.TastingNoteUI.tastingRecordBadge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(style == .listThumbnail ? Color(.systemGray) : .white)
                    .padding(.horizontal, 12)
                    .frame(height: style.badgeHeight)
                    .background(
                        style == .listThumbnail
                        ? Color(red: 0.97, green: 0.95, blue: 0.92)
                        : Color(.systemGray)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.top, style.badgeTopInset)
                    .padding(.leading, style.badgeLeadingInset)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showsHeartIcon {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: style.likeIconSize, weight: .semibold))
                    .foregroundColor(isLiked ? Color(.systemGray) : Color(.systemGray2))
                    .padding(.trailing, style.likeIconInset)
                    .padding(.bottom, style.likeIconInset)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
}

struct PerfumeCardHeartButton: View {
    let isLiked: Bool
    var style: PerfumeCardStyle = .grid
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: style.likeIconSize, weight: .semibold))
                .foregroundColor(isLiked ? Color(.systemGray) : Color(.systemGray2))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct PerfumeCardArtworkView: View {
    let imageURL: String?
    var style: PerfumeCardStyle = .grid

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(PerfumeGridCardLayout.cardBackgroundColor)

            RoundedRectangle(cornerRadius: style.innerCanvasCornerRadius)
                .fill(Color.white)
                .padding(style.innerCanvasInset)

            GeometryReader { geometry in
                let canvasWidth = geometry.size.width - (style.innerCanvasInset * 2)
                let canvasHeight = geometry.size.height - (style.innerCanvasInset * 2)

                artworkContent
                    .frame(
                        width: max(0, canvasWidth * style.artworkWidthRatio),
                        height: max(0, canvasHeight * style.artworkHeightRatio)
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }

    @ViewBuilder
    private var artworkContent: some View {
        if let imageURL,
           let resolvedURL = URL(string: imageURL) {
            KFImage(resolvedURL)
                .cacheOriginalImage()
                .fade(duration: 0.2)
                .setProcessor(perfumeArtworkBackgroundCleanupProcessor)
                .placeholder {
                    placeholderView
                }
                .resizable()
                .scaledToFit()
                .padding(style.imagePadding)
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        Image(systemName: "shippingbox")
            .font(.system(size: style.placeholderIconSize))
            .foregroundColor(Color(.systemGray3))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PerfumeCardTextContentView: View {
    let brand: String
    let name: String
    let accords: [String]
    var style: PerfumeCardStyle = .grid

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(PerfumePresentationSupport.displayBrand(brand))
                .font(.system(size: style.brandFontSize, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    minHeight: style.brandHeight,
                    maxHeight: style.brandHeight,
                    alignment: .topLeading
                )

            Text(PerfumePresentationSupport.displayPerfumeName(name))
                .font(.system(size: style.nameFontSize, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .lineSpacing(style.nameLineSpacing)
                .multilineTextAlignment(.leading)
                .padding(.top, style.brandToNameSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            PerfumeGridCardAccordLine(
                accords: accords,
                style: style
            )
            .padding(.top, style.nameToAccordSpacing)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            if style.usesFixedTextBlockHeight {
                Spacer(minLength: 0)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: style.textBlockHeight,
            maxHeight: style.textBlockHeight,
            alignment: .topLeading
        )
    }
}

struct PerfumeGridCardAccordLine: View {
    let accords: [String]
    var style: PerfumeCardStyle = .grid

    var body: some View {
        let displayAccords = PerfumePresentationSupport.displayAccords(Array(accords.prefix(2)))

        HStack(spacing: style.accordSpacing) {
            ForEach(Array(displayAccords.enumerated()), id: \.offset) { index, accord in
                HStack(spacing: 4) {
                    Circle()
                        .fill(index == 0 ? Color(red: 0.97, green: 0.67, blue: 0.67) : Color(.systemGray3))
                        .frame(width: style.accordDotSize, height: style.accordDotSize)

                    Text(accord)
                        .font(.system(size: style.accordFontSize, weight: .regular))
                        .foregroundColor(Color(.systemGray2))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct PerfumeArtworkBackgroundCleanupProcessor: ImageProcessor {
    let identifier = "com.sniff.perfume-artwork-background-cleanup.v2"

    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image.removingEdgeConnectedWhiteBackground()
        case .data(let data):
            guard let image = KFCrossPlatformImage(data: data) else { return nil }
            return image.removingEdgeConnectedWhiteBackground()
        }
    }
}

private extension UIImage {
    func removingEdgeConnectedWhiteBackground() -> UIImage {
        guard let cgImage else { return self }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              let rawPointer = context.data else {
            return self
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)

        let pixels = rawPointer.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        var visited = Array(repeating: false, count: width * height)
        var queue = ContiguousArray<Int>()
        queue.reserveCapacity(width * 2 + height * 2)

        func offset(for index: Int) -> Int {
            index * bytesPerPixel
        }

        func isSoftWhite(pixelIndex: Int) -> Bool {
            let pixelOffset = offset(for: pixelIndex)
            let red = pixels[pixelOffset]
            let green = pixels[pixelOffset + 1]
            let blue = pixels[pixelOffset + 2]
            let alpha = pixels[pixelOffset + 3]

            guard alpha > 0 else { return false }

            let maxValue = max(red, max(green, blue))
            let minValue = min(red, min(green, blue))
            let channelDiff = maxValue - minValue

            return red >= 244 && green >= 244 && blue >= 244 && channelDiff <= 10
        }

        func enqueueIfNeeded(_ index: Int) {
            guard index >= 0, index < width * height, !visited[index], isSoftWhite(pixelIndex: index) else {
                return
            }

            visited[index] = true
            queue.append(index)
        }

        for x in 0..<width {
            enqueueIfNeeded(x)
            enqueueIfNeeded((height - 1) * width + x)
        }

        for y in 0..<height {
            enqueueIfNeeded(y * width)
            enqueueIfNeeded(y * width + (width - 1))
        }

        var queueIndex = 0

        while queueIndex < queue.count {
            let current = queue[queueIndex]
            queueIndex += 1

            let x = current % width
            let y = current / width

            if x > 0 { enqueueIfNeeded(current - 1) }
            if x < width - 1 { enqueueIfNeeded(current + 1) }
            if y > 0 { enqueueIfNeeded(current - width) }
            if y < height - 1 { enqueueIfNeeded(current + width) }
        }

        for index in queue {
            let pixelOffset = offset(for: index)
            let red = pixels[pixelOffset]
            let green = pixels[pixelOffset + 1]
            let blue = pixels[pixelOffset + 2]
            let alpha = pixels[pixelOffset + 3]

            let isHardWhite = red >= 250 && green >= 250 && blue >= 250
            pixels[pixelOffset + 3] = isHardWhite ? 0 : min(alpha, 24)
        }

        guard let outputImage = context.makeImage() else { return self }
        return UIImage(cgImage: outputImage, scale: scale, orientation: imageOrientation)
    }
}
