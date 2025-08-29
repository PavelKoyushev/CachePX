import Foundation
import UIKit

protocol CacheManagerProtocol {
    
    func сacheSize() async -> (String, String)
    func cleanCache() async
}

public actor CacheManager: CacheManagerProtocol {
    
    public static let shared = CacheManager()
    
    let fileManager = FileManager.default
    
    private init() {}
}

extension CacheManager {
    
    public func сacheSize() async -> (String, String) {
        if let size = await sizeOfFiles(), let totalSpace = getTotalDiskSpace() {
            
            let totalSpaceInMB = Double(totalSpace) / (1024 * 1024)
            
            let percent = (size / totalSpaceInMB) * 100
            
            return (String(format: "%.1f", size), String(format: "%.2f", percent))
        } else {
            return ("0 MB", "0%")
        }
    }
    
    private func getTotalDiskSpace() -> Int64? {
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSpace = attributes[.systemSize] as? Int64 {
                return totalSpace
            }
        } catch {
            Logger.shared.logEvent("Error getting total space: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func sizeOfFiles() async -> Double? {
        
        guard let libraryDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first,
              let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        let directoriesToScan = [tempDirectory, libraryDirectory, cachesDirectory]
        var totalSize: Int64 = 0
        
        for directoryURL in directoriesToScan {
            guard let enumerator = fileManager.enumerator(at: directoryURL,
                                                          includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                                                          errorHandler: nil) else { continue }
            
            for case let fileURL as URL in enumerator {
                let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                if resourceValues?.isDirectory != true {
                    totalSize += Int64(resourceValues?.fileSize ?? 0)
                }
            }
        }
        
        // Конвертируем в мегабайты
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        return sizeInMB
    }
}

//MARK: Clean cache
extension CacheManager {
    
    public func cleanCache() async {
        
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            
            await StorageService.shared.closeDatabase()
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            if await !cleanDirectory(at: cachesURL) {
                Logger.shared.logEvent("Unable to clear caches folder")
            }
        }
        
        if await !cleanDirectory(at: tmpURL) {
            Logger.shared.logEvent("Unable to clear tmp folder")
        }
        
        DirectoryManager.shared.resetCreated()
        StorageService.shared.setup()
    }
    
    private func cleanDirectory(at url: URL) async -> Bool {
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            
            return true
        } catch {
            Logger.shared.logEvent("Error while clearing \(url.lastPathComponent): \(error.localizedDescription)")
            return false
        }
    }
}
