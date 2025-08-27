import Foundation

struct ImageResponse: Sendable {
    
    let url: URL
    let data: Data
    let etag: String
    let lastModified: String
}
