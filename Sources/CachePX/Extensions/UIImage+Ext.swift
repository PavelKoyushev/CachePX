import UIKit

extension UIImage {
    
    func downsample(to maxSize: CGSize) async -> UIImage? {
        let originalSize = self.size
        
        let widthScale = maxSize.width / originalSize.width
        let heightScale = maxSize.height / originalSize.height
        let scaleFactor = min(widthScale, heightScale, 1)
        
        let targetSize = CGSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let downsampledImage = renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return downsampledImage
    }
}
