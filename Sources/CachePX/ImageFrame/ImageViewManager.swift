import Foundation.NSURL
import Combine

final class ImageViewManager: ObservableObject {
    
    @Published private(set) var state: LoadState = .loading
    
    private var loadedURL: URL?
    private var task: Task<Void, Never>?
    private let service: ImageDownloaderProtocol
    
    init(options: LoadOptions?) {
        self.service = ImageDownloader(
            cache: ImageStorageManager(directoryURL: DirectoryManager.shared.cacheImagesURL),
            loadService: NetworkService(),
            options: options
        )
    }
    
    func loadImage(from url: URL) {
        guard loadedURL != url else { return }
        
        task?.cancel()
        task = Task(priority: .userInitiated) { [weak self] in
            await MainActor.run { [weak self] in
                if case .image = self?.state { return }
                self?.state = .loading
            }
            
            do {
                if let stream = await self?.service.imageStreamWithThrowing(from: url.absoluteString) {
                    for try await img in stream {
                        await MainActor.run { [weak self] in
                            self?.state = .image(img)
                        }
                    }
                    await MainActor.run { [weak self] in
                        self?.loadedURL = url
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { [weak self] in
                        if case .image = self?.state { return }
                        self?.state = .error
                    }
                }
            }
        }
    }
    
    func cancelTask() {
        task?.cancel()
        task = nil
    }
}
