import Foundation
import UIKit

protocol NetworkServiceProtocol {
    
    func fetchImageIfNeeded(from url: URL, metadata: ImageCacheMetadata) async throws -> ImageResponse
    func downloadImage(from urlString: String) async throws -> ImageResponse
}

struct NetworkService: NetworkServiceProtocol {
    
    func fetchImageIfNeeded(from url: URL, metadata: ImageCacheMetadata) async throws -> ImageResponse {
        
        let request = await request(from: url, metadata: metadata)
        
        let (data, response) = try await URLSession.cached.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.shared.logEvent("\(NetworkError.invalidResponse.description): \(url.absoluteString)")
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 304 {
            
            Logger.shared.logEvent("\(NetworkError.notModified.description): \(url.absoluteString), etag - \(metadata.etag), lastModified - \(metadata.lastModified)")
            throw NetworkError.notModified
            
        } else if let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) {
            
            let etag = httpResponse.value(forHTTPHeaderField: "ETag") ?? ""
            let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified") ?? ""
            
            Logger.shared.logEvent("✅ New image downloaded: \(url.absoluteString), etag - \(etag), lastModified - \(lastModified)")
            return ImageResponse(url: url, data: data, etag: etag, lastModified: lastModified)
        } else {
            
            Logger.shared.logEvent("\(NetworkError.serverError(statusCode: httpResponse.statusCode).description): \(url.absoluteString)")
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    func downloadImage(from urlString: String) async throws -> ImageResponse {
        
        guard let url = URL(string: urlString) else {
            Logger.shared.logEvent(NetworkError.invalidURL.description)
            throw NetworkError.invalidURL
        }
        
        let request = await request(from: url, metadata: nil)
        
        do {
            let (data, response) = try await URLSession.cached.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.shared.logEvent(NetworkError.invalidResponse.description)
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let etag = httpResponse.value(forHTTPHeaderField: "ETag") ?? ""
                let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified") ?? ""
                
                return ImageResponse(url: url, data: data, etag: etag, lastModified: lastModified)
            default:
                Logger.shared.logEvent("\(NetworkError.serverError(statusCode: httpResponse.statusCode).description): \(urlString)")
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch {
            Logger.shared.logEvent(NetworkError.networkError(error).description)
            throw NetworkError.networkError(error)
        }
    }
}

private extension NetworkService {
    
    func request(from url: URL, metadata: ImageCacheMetadata?) async -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let metadata {
            
            if !metadata.etag.isEmpty {
                request.setValue(metadata.etag, forHTTPHeaderField: "If-None-Match")
            } else if !metadata.lastModified.isEmpty {
                request.addValue(metadata.lastModified, forHTTPHeaderField: "If-Modified-Since")
            }
        }
        
        return request
    }
}
