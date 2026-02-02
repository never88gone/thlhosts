
import Foundation

import Swifter

class HostsManager {
    static let shared = HostsManager()
    private let server = HttpServer()
    
    struct HostRule {
        let ip: String
        let domain: String
        let enabled: Bool
    }
    
    private(set) var rules: [HostRule] = []
    
    func loadRules() {
        // Load from UserDefaults or Shared Container
    }
    
    var onHostsUploaded: ((String) -> Void)?
    
    func startServer(port: in_port_t = 8080) {
        // Setup Route
        server["/upload"] = { [weak self] request in
            guard let self = self else { return .internalServerError(nil) }
            if let body = String(bytes: request.body, encoding: .utf8) {
                print("Received upload content: \(body.prefix(50))...")
                DispatchQueue.main.async {
                    self.onHostsUploaded?(body)
                }
                return .ok(.text("Uploaded Successfully"))
            }
            return .badRequest(.text("Invalid body"))
        }
        
        server["/hello"] = { .ok(.htmlBody("You asked for \($0)")) }
        
        do {
            try server.start(port)
            print("Server started on port \(port)")
        } catch {
            print("Server start error: \(error)")
        }
    }
    
    func stopServer() {
        server.stop()
    }
    
    func parse(hostsContent: String) -> [HostRule] {
        var parsedRules: [HostRule] = []
        let lines = hostsContent.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 2 {
                let ip = String(parts[0])
                let domain = String(parts[1])
                parsedRules.append(HostRule(ip: ip, domain: domain, enabled: true))
            }
        }
        return parsedRules
    }
    
    func updateRules(_ newRules: [HostRule]) {
        self.rules = newRules
        // Save and trigger VPN update if needed
    }
}
