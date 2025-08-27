import Foundation

public struct LoadOptions: Sendable {
    
    public init(downSample: CGSize?) {
        self.downSample = downSample
    }
    
    public let downSample: CGSize?
}
