import Foundation

protocol DirectoryProviderProtocol {
    var directoryURL: URL { get }
    func resetCreated()
}

final class DirectoryProvider: DirectoryProviderProtocol {
    
    private let fileManager = FileManager.default
    private let directoryName: String
    private let pathDirectory: FileManager.SearchPathDirectory
    private let pathDomainMask: FileManager.SearchPathDomainMask
    
    private var isCreated: Bool = false
    
    init(directoryName: String,
         pathDirectory: FileManager.SearchPathDirectory,
         pathDomainMask: FileManager.SearchPathDomainMask) {
        
        self.directoryName = directoryName
        self.pathDirectory = pathDirectory
        self.pathDomainMask = pathDomainMask
    }
    
    var directoryURL: URL {
        let directories = fileManager.urls(for: pathDirectory, in: pathDomainMask)
        let directoryURL = directories[0].appendingPathComponent(directoryName)
        
        if !isCreated {
            do {
                try fileManager.createDirectory(at: directoryURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
                isCreated = true
            } catch {
                Logger.shared.logEvent("Failed to create directory \(directoryName)")
            }
        }
        
        return directoryURL
    }
    
    func resetCreated() {
        isCreated = false
    }
}
