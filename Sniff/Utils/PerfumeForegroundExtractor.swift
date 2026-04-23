import UIKit
import Vision
import CoreImage

enum PerfumeForegroundExtractor {

    @available(iOS 17.0, *)
    static func extractForeground(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.normalizedCGImage else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])

            guard
                let observation = request.results?.first,
                !observation.allInstances.isEmpty
            else {
                return nil
            }

            let maskedPixelBuffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )

            let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
            let context = CIContext(options: nil)
            let extent = ciImage.extent.integral

            guard let outputCGImage = context.createCGImage(ciImage, from: extent) else {
                return nil
            }

            return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: .up)
        } catch {
            return nil
        }
    }
}

private extension UIImage {
    var normalizedCGImage: CGImage? {
        if imageOrientation == .up, let cgImage {
            return cgImage
        }

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = scale
        rendererFormat.opaque = false

        let renderedImage = UIGraphicsImageRenderer(size: size, format: rendererFormat).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }

        return renderedImage.cgImage
    }
}
