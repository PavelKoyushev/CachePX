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
            let task = Task {
                do {
                    guard let url = URL(string: urlString) else {
                        Logger.shared.logEvent("\(ErrorLoad.invalidURL.description): \(urlString)")
                        throw ErrorLoad.invalidURL
                    }
                    try await load(url: url, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private extension ImageDownloader {
    
    func load(url: URL, continuation: AsyncThrowingStream<UIImage, Error>.Continuation) async throws {
        let urlString = url.absoluteString
        
        guard let metadata = await db.getDateForImage(with: urlString) else {
            try Task.checkCancellation()
            let result = try await loadService.downloadImage(from: urlString)
            try await handleDownloadedImage(result, localPath: nil, continuation: continuation)
            return
        }
        
        try Task.checkCancellation()
        let cached = try await cache.image(fileName: metadata.localPath)
        if let cached { continuation.yield(cached) }
        
        if metadata.notModified {
            guard cached != nil else {
                Logger.shared.logEvent("\(ErrorLoad.cache.description): \(urlString)")
                throw ErrorLoad.cache
            }
            return
        }
        
        try Task.checkCancellation()
        let result = try await loadService.fetchImageIfNeeded(from: url, metadata: metadata)
        try await handleDownloadedImage(result, localPath: metadata.localPath, continuation: continuation)
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
           let data = result.data.resized(width: size.width, height: size.height, quality: size.quality),
           let imageResult = UIImage(data: data),
           let path = try await cache.save(data: data, fileName: result.url.fileName(localPath)) {
            
            await upsertImage(result, filePath: path)
            continuation.yield(imageResult)
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
