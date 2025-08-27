import Foundation

struct FileIO {
    
    static func save(data: Data, directoryURL: URL, fileName: String) async throws -> String {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: [.atomic])
        return fileURL.lastPathComponent
    }
    
    static func read(directoryURL: URL, fileName: String) async throws -> Data {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        return try Data(contentsOf: fileURL)
    }
}
