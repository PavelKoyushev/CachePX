import Foundation.NSURL
import Combine

@MainActor
final class ImageViewManager: ObservableObject {
    
    private(set) var state: LoadState = .loading
    private(set) var isLoaded: Bool = false
    private var task: Task<Void, Never>? = nil
    
    private let directoryManager: DirectoryManagerProtocol
    private let imageStorage: ImageStorageProtocol
    private let loadService: NetworkServiceProtocol
    private let service: ImageDownloaderProtocol
    
    private let options: LoadOptions?
    
    init(options: LoadOptions?) {
        self.options = options
        
        self.directoryManager = DirectoryManager.shared
        self.imageStorage = ImageStorageManager(directoryURL: directoryManager.cacheImagesURL)
        self.loadService = NetworkService()
        self.service = ImageDownloader(cache: imageStorage,
                                       loadService: loadService,
                                       options: options)
    }
}

extension ImageViewManager {
    
    func loadImage(from url: URL) {
        guard !isLoaded else { return }
        
        task = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                await Task.yield()
                
                if let stream = await self?.service.imageStreamWithThrowing(from: url.absoluteString) {
                    for try await img in stream {
                        await MainActor.run { [weak self] in
                            self?.state = .image(img)
                            self?.isLoaded = true
                            self?.objectWillChange.send()
                        }
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.state = .error
                    self?.objectWillChange.send()
                }
            }
        }
    }
    
    func cancelTask() {
        DispatchQueue.main.async { [weak self] in
            self?.task?.cancel()
            self?.task = nil
        }
    }
}
