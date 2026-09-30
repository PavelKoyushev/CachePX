import Foundation.NSURL
import Combine

final class ImageViewManager: ObservableObject {
    
    @Published private(set) var state: LoadState = .loading
    
    private var loadedURL: URL?
    private let service: ImageDownloaderProtocol
    
    init(options: LoadOptions?) {
        self.service = ImageDownloader(
            cache: ImageStorageManager(directoryURL: DirectoryManager.shared.cacheImagesURL),
            loadService: NetworkService(),
            options: options
        )
    }
    
    func load(from url: URL) async {
        guard loadedURL != url else { return }
        
        await MainActor.run { [weak self] in
            if case .image = self?.state { return }
            self?.state = .loading
        }
        
        do {
            let stream = await service.imageStreamWithThrowing(from: url.absoluteString)
            
            for try await img in stream {
                await MainActor.run { [weak self] in
                    self?.state = .image(img)
                }
            }
            await MainActor.run { [weak self] in
                self?.loadedURL = url
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
