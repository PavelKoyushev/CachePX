import Foundation

/// Prefetches images into cache with limited concurrency, so background loading
/// doesn't compete with user-facing image requests.
///
/// Safe to share across multiple independent callers: each URL is tracked and
/// cancelled independently, so a `prefetch(for:)` call from one place never
/// affects URLs requested elsewhere.
public actor ImagePrefetcher {
    
    public let options: LoadOptions?
    private let service: ImageDownloaderProtocol
    private let limiter: TaskLimiter
    private var tasks: [URL: Task<Void, Never>] = [:]
    
    public init(options: LoadOptions? = nil, maxConcurrent: Int = 5) {
        self.options = options
        self.limiter = TaskLimiter(maxConcurrentTasks: maxConcurrent)
        self.service = ImageDownloader(cache: ImageStorageManager(directoryURL: DirectoryManager.shared.cacheImagesURL),
                                       loadService: NetworkService(),
                                       options: options)
    }
    
    /// Starts prefetching the given URLs, at most `maxConcurrent` at a time.
    /// URLs already being prefetched are skipped, not restarted.
    public func prefetch(for urls: [URL]) {
        for url in urls {
            guard tasks[url] == nil else { continue }
            
            tasks[url] = Task(priority: .utility) { [weak self] in
                await self?.limiter.acquire()
                defer {
                    Task {
                        await self?.limiter.release()
                    }
                }
                
                do {
                    try Task.checkCancellation()
                    _ = await self?.service.imageStreamWithThrowing(from: url.absoluteString)
                } catch {
                    // CancellationError
                }
                await self?.taskFinished(for: url)
            }
        }
    }
    
    /// Cancels prefetch for a single URL, if it's in progress.
    public func cancelPrefetch(for url: URL) {
        tasks[url]?.cancel()
        tasks[url] = nil
    }
    
    /// Cancels every prefetch currently in progress.
    public func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    private func taskFinished(for url: URL) {
        tasks[url] = nil
    }
}
