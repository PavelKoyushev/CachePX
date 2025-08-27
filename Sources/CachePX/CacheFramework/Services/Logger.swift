import Foundation

public protocol ExternalLogger {
    var name: String { get }
    func logEvent(event: String)
}

public final class Logger {
    
    public static let shared = Logger()
    
    private var externalLoggers = [ExternalLogger]()
    
    private init() {}
    
    public func subscribe(_ newLogger: ExternalLogger) {
        externalLoggers.append(newLogger)
    }
    
    public func logEvent(_ event: String) {
        for logger in externalLoggers {
            logger.logEvent(event: logger.name + ": " + event)
        }
    }
}
