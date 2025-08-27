import Foundation

struct ImageCacheMetadata: Sendable {
    
    let etag: String
    let lastModified: String
    let localPath: String
}

extension ImageCacheMetadata {
    
    var notModified: Bool {
        etag.isEmpty && lastModified.isEmpty
    }
}
