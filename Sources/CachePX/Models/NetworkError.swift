import Foundation

enum NetworkError: Error {
    
    case invalidURL
    case invalidResponse
    case notModified // 304
    case serverError(statusCode: Int)
    case networkError(_ error: Error)
    case unknown
    
    var description: String {
        switch self {
        case .invalidURL:
            return "URL address is invalid"
        case .invalidResponse:
            return "Unexpected server response"
        case .notModified:
            return "The image remained unchanged"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .networkError(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .unknown:
            return "Unknown error"
        }
    }
}
