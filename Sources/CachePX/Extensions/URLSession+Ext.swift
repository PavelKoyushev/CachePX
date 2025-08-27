import Foundation

extension URLSession {
    
    static let cached: URLSession = {
        let config = URLSessionConfiguration.default
        
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 12
        return URLSession(configuration: config)
    }()
}
