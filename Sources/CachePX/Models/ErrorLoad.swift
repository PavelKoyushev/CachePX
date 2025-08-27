import Foundation

enum ErrorLoad: Error {
    
    case invalidURL
    case invalidImageData
    case cache
    case cacheSave
    case unknown
    
    var description: String {
        switch self {
        case .invalidURL:
            return "URL address is invalid"
        case .invalidImageData:
            return "Invalid image data"
        case .cache:
            return "Error reading from cache"
        case .cacheSave:
            return "Error saving to cache"
        case .unknown:
            return "Unknown error"
        }
    }
}
