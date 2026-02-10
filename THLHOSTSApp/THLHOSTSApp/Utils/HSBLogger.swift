import Foundation

class HSBLogger {
    static let shared = HSBLogger()
    
    private(set) var logs: [String] = []
    private let queue = DispatchQueue(label: "com.thlhosts.logger")
    
    // Notification for UI updates
    static let didUpdateLogs = Notification.Name("HSBLoggerDidUpdateLogs")
    
    private init() {}
    
    enum LogLevel: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case debug = "DEBUG"
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(fileName):\(line) - \(message)"
        
        queue.async {
            self.logs.append(logMessage)
            // efficient memory management: keep last 1000 logs
            if self.logs.count > 1000 {
                self.logs.removeFirst(self.logs.count - 1000)
            }
            
            DispatchQueue.main.async {
                // Print to console for debugging
                print(logMessage) 
                NotificationCenter.default.post(name: HSBLogger.didUpdateLogs, object: nil)
            }
        }
    }
    
    func clear() {
        queue.async {
            self.logs.removeAll()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: HSBLogger.didUpdateLogs, object: nil)
            }
        }
    }
}
