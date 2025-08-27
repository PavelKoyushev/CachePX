import Foundation
import UIKit

protocol ImageStorageProtocol {
    
    func save(data: Data, fileName: String) async throws -> String?
    func image(fileName: String) async throws -> UIImage?
}

public struct ImageStorageManager: ImageStorageProtocol {
    
    let directoryURL: URL
    
    func save(data: Data, fileName: String) async throws -> String? {
        try await FileIO.save(data: data,
                              directoryURL: directoryURL,
                              fileName: fileName)
    }
    
    func image(fileName: String) async throws -> UIImage? {
        let data = try await FileIO.read(directoryURL: directoryURL,
                                         fileName: fileName)
        return UIImage(data: data)
    }
}
