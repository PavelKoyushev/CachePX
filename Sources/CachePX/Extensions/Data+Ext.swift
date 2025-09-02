import Foundation
import CachePXCore

extension Data {
    
    func resized(width: Int, height: Int, quality: Int) -> Data? {
        ImageProcessor.resizeImageData(
            self,
            width: Int32(width),
            height: Int32(height),
            quality: Int32(quality)
        ) as Data?
    }
}
