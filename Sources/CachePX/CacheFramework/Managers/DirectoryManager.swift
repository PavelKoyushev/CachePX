import Foundation

protocol DirectoryManagerProtocol {
    var cacheImagesURL: URL { get }
    var dataBaseURL: URL { get }
    func resetCreated()
}

final class DirectoryManager: DirectoryManagerProtocol {
    
    static let shared = DirectoryManager()
    
    private var providers: [DirectoryType: DirectoryProvider] = [:]
    
    private init() {
        providers[.cacheImages] = DirectoryProvider(
            directoryName: DirectoryType.cacheImages.rawValue,
            pathDirectory: .cachesDirectory,
            pathDomainMask: .userDomainMask
        )
        
        providers[.dataBase] = DirectoryProvider(
            directoryName: DirectoryType.dataBase.rawValue,
            pathDirectory: .cachesDirectory,
            pathDomainMask: .userDomainMask
        )
    }
    
    var cacheImagesURL: URL {
        providers[.cacheImages]!.directoryURL
    }
    
    var dataBaseURL: URL {
        providers[.dataBase]!.directoryURL
    }
    
    func resetCreated() {
        providers.forEach {
            $0.value.resetCreated()
        }
    }
}
