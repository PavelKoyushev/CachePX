import Foundation
import UIKit.UIImage

enum LoadState: Sendable {
    
    case loading
    case error
    case image(UIImage)
}
