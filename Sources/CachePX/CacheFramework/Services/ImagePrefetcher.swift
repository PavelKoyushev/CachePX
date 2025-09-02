import Foundation

public class ImagePrefetcher {
    
    public let options: LoadOptions?
    private let service: ImageDownloaderProtocol
    
    public init(options: LoadOptions? = nil) {
        self.options = options
        self.service = ImageDownloader(cache: ImageStorageManager(directoryURL: DirectoryManager.shared.cacheImagesURL),
                                       loadService: NetworkService(),
                                       options: options)
    }
    
    public func prefetch(for urls: [URL]) {
        Task(priority: .utility) {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = await self.service.imageStreamWithThrowing(from: url.absoluteString)
                    }
                }
            }
        }
    }
}
