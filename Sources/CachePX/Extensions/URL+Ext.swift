import Foundation

extension URL {
    
    @inlinable
    func fileName(_ localPath: String?) -> String {
        guard let localPath else {
            return self.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        }
        return localPath
    }
}
