import Foundation
import UIKit.UIImage

protocol ImageDownloaderProtocol {
    
    func imageStreamWithThrowing(from urlString: String) async -> AsyncThrowingStream<UIImage, Error>
}

struct ImageDownloader {
    
    private let db = StorageService.shared
    private let cache: ImageStorageProtocol
    private let loadService: NetworkServiceProtocol
    private let options: LoadOptions?
    
    init(cache: ImageStorageProtocol,
         loadService: NetworkServiceProtocol,
         options: LoadOptions?) {
        
        self.cache = cache
        self.loadService = loadService
        self.options = options
    }
}

extension ImageDownloader: ImageDownloaderProtocol {
    
    func imageStreamWithThrowing(from urlString: String) async -> AsyncThrowingStream<UIImage, Error> {
        
        AsyncThrowingStream { continuation in
            Task(priority: .userInitiated) {
                guard let url = URL(string: urlString) else {
                    Logger.shared.logEvent("\(ErrorLoad.invalidURL.description): \(urlString)")
                    continuation.finish(throwing: ErrorLoad.invalidURL)
                    return
                }
                
                if let metadata = await db.getDateForImage(with: urlString) {
                    
                    await Task.yield()
                    try Task.checkCancellation()
                    
                    if metadata.notModified {
                        if let image = try await cache.image(fileName: metadata.localPath) {
                            continuation.yield(image)
                            continuation.finish()
                        } else {
                            Logger.shared.logEvent("\(ErrorLoad.cache.description): \(urlString)")
                            continuation.finish(throwing: ErrorLoad.cache)
                        }
                    } else {
                        
                        if let cachedImage = try await cache.image(fileName: metadata.localPath) {
                            continuation.yield(cachedImage)
                        }
                        
                        let result = try await loadService.fetchImageIfNeeded(from: url, metadata: metadata)
                        try await handleDownloadedImage(result, localPath: metadata.localPath, continuation: continuation)
                        
                        continuation.finish()
                    }
                } else {
                    await Task.yield()
                    try Task.checkCancellation()
                    
                    do {
                        let result = try await loadService.downloadImage(from: urlString)
                        try await handleDownloadedImage(result, localPath: nil, continuation: continuation)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
}

private extension ImageDownloader {
    
    func handleDownloadedImage(_ result: ImageResponse,
                               localPath: String?,
                               continuation: AsyncThrowingStream<UIImage, Error>.Continuation) async throws {
        guard let image = UIImage(data: result.data) else {
            Logger.shared.logEvent(ErrorLoad.invalidImageData.description + " " + result.url.absoluteString)
            throw ErrorLoad.invalidImageData
        }
        
        if let size = options?.downSample,
           let downsampled = await image.downsample(to: size),
           let data = downsampled.jpegData(compressionQuality: 1),
           let path = try await cache.save(data: data, fileName: result.url.fileName(localPath)) {
            
            await upsertImage(result, filePath: path)
            continuation.yield(downsampled)
        } else if let path = try await cache.save(data: result.data, fileName: result.url.fileName(localPath)) {
            
            await insertImage(result, filePath: path)
            continuation.yield(image)
        } else {
            Logger.shared.logEvent(ErrorLoad.cacheSave.description + " " + result.url.absoluteString)
            throw ErrorLoad.cacheSave
        }
    }
}

private extension ImageDownloader {
    
    func insertImage(_ value: ImageResponse, filePath: String) async {
        await db.insertImage(
            url: value.url.absoluteString,
            etag: value.etag,
            lastModified: value.lastModified,
            localPath: filePath
        )
    }
    
    func upsertImage(_ value: ImageResponse, filePath: String) async {
        await db.upsertImage(
            url: value.url.absoluteString,
            etag: value.etag,
            lastModified: value.lastModified,
            localPath: filePath
        )
    }
}
