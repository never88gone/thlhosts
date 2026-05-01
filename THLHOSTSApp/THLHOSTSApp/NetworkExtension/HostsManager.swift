
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
    
    var onHostsUploaded: ((String, String) -> Void)?
    
    func startServer(port: in_port_t = 8080) {
        // Serve upload.html
        server["/"] = { request in
            if let path = Bundle.main.path(forResource: "upload", ofType: "html"),
               let html = try? String(contentsOfFile: path) {
                return .ok(.htmlBody(html))
            }
            return .notFound()
        }
        
        server["/upload"] = { [weak self] request in
            guard let self = self else { return .internalServerError(nil) }
            
            // Handle Multipart
            let body = request.body
            if !body.isEmpty {
                let data = Data(body)
                // Simple Multipart Parser (Swifter might not have one exposed easily, implementing basic check)
                // Actually Swifter has MultiPart parsing in parseUrlencodedForm or similar but let's try manual for robustness with binary data if needed,
                // or just assume standard multipart.
                
                // For simplicity, let's assume standard multipart form data.
                // We need to extract "name" and "file" content.
                // Since Swifter's multipart parsing can be tricky, let's look for boundaries.
                
                // IMPORTANT: Swifter typically parses body in `request.parseMultiPartFormData()` but it depends on version.
                // Let's try to parse manually if needed or use Swifter's method if available.
                // Checking Swifter standard usage: `MultiPartParser`
                
                // Get Boundary from Content-Type (Case Insensitive)
                let contentType = request.headers.first { $0.key.lowercased() == "content-type" }?.value ?? ""
                
                // Robust Boundary Extraction
                var boundary = ""
                let params = contentType.components(separatedBy: ";")
                for param in params {
                    let trimmed = param.trimmingCharacters(in: .whitespaces)
                    if trimmed.lowercased().hasPrefix("boundary=") {
                        let boundaryRaw = String(trimmed.dropFirst("boundary=".count))
                        boundary = boundaryRaw.trimmingCharacters(in: .init(charactersIn: "\""))
                        break
                    }
                }
                
                log("DEBUG: Content-Type: \(contentType)", level: .debug)
                log("DEBUG: Boundary: \(boundary)", level: .debug)
                log("DEBUG: Body Size: \(data.count)", level: .debug)
                
                let parts = SimpleMultiPartParser.parse(data: data, boundary: boundary)
                log("DEBUG: Parsed Parts: \(parts.count)", level: .debug)
                
                var name = "Uploaded"
                var fileContent = ""
                
                for part in parts {
                    // Normalize header keys for case-insensitive lookup
                    let headers = part.headers.reduce(into: [String:String]()) { $0[$1.key.lowercased()] = $1.value }
                    
                    guard let disposition = headers["content-disposition"] else { continue }
                    
                    // Parse Content-Disposition params
                    var partName = ""
                    let dispoParams = disposition.components(separatedBy: ";")
                    for param in dispoParams {
                        let kv = param.trimmingCharacters(in: .whitespaces).components(separatedBy: "=")
                        if kv.count == 2 {
                            let key = kv[0].lowercased()
                            let val = kv[1].trimmingCharacters(in: .init(charactersIn: "\""))
                            if key == "name" { partName = val }
                        }
                    }
                    
                    log("DEBUG: Part Name Detected: \(partName)", level: .debug)
                    
                    if partName == "name", let body = String(data: part.body, encoding: .utf8) {
                        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            name = trimmed
                        }
                    } else if partName == "file", let body = String(data: part.body, encoding: .utf8) {
                         fileContent = body
                         log("DEBUG: File content found, length: \(body.count)", level: .debug)
                    }
                }
                
                if !fileContent.isEmpty {
                    log("Received upload: Name=\(name), ContentLength=\(fileContent.count)", level: .info)
                    DispatchQueue.main.async {
                        self.onHostsUploaded?(name, fileContent)
                    }
                    return .ok(.text("Uploaded Successfully to list: \(name)"))
                }
            }
             
            return .badRequest(.text("Invalid body or missing file. Debug Info: Parts=\(SimpleMultiPartParser.lastParseCount)"))
        }
        
        server["/hello"] = { .ok(.htmlBody("You asked for \($0)")) }
        
        do {
            try server.start(port)
            log("Server started on port \(port)", level: .info)
        } catch {
            log("Server start error: \(error)", level: .error)
        }
    }

    private enum LogLevel: String { case info, warning, error, debug }
    private func log(_ message: String, level: LogLevel = .info) {
        #if canImport(UIKit)
        // If possible, try to use the shared logger (for Main App)
        // This is a dynamic check that works if the symbol is available
        // But for simplicity and to avoid compilation errors, we just print here
        #endif
        print("[HostsManager] [\(level.rawValue.uppercased())] \(message)")
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

// MARK: - Simple MultiPart Parser
struct SimpleMultiPartParser {
    static var lastParseCount = 0
    
    struct Part {
        let headers: [String: String]
        let body: Data
    }
    
    static func parse(data: Data, boundary: String) -> [Part] {
        lastParseCount = 0
        var parts: [Part] = []
        // Validate boundary
        if boundary.isEmpty { return [] }
        
        // Boundaries are prefixed with "--"
        guard let boundaryData = "--\(boundary)".data(using: .utf8) else { return [] }
        
        // Split data by boundary
        let chunks = split(data: data, separator: boundaryData)
        
        for chunk in chunks {
            // Each chunk is: [CRLF]<headers>[CRLF][CRLF]<body>[CRLF]
            // or just [CRLF] (epilogue)
            
            // 1. Skip if too small
            if chunk.count < 4 { continue }
            
            // 2. Scan for Double CRLF (\r\n\r\n) OR Double LF (\n\n) for robustness
            var headerEndRange: Range<Data.Index>? = nil
            var separatorLength = 0
            
            if let r = chunk.range(of: "\r\n\r\n".data(using: .utf8)!) {
                headerEndRange = r
                separatorLength = 4
            } else if let r = chunk.range(of: "\n\n".data(using: .utf8)!) {
                 headerEndRange = r
                 separatorLength = 2
            }
            
            guard let range = headerEndRange else { continue }
            
            let fullHeaderData = chunk.subdata(in: 0..<range.lowerBound)
            let bodyData = chunk.subdata(in: range.upperBound..<chunk.count)
            
            // 3. Clean up headers (remove leading CRLF/LF if present from previous boundary)
            // It's safer to just parse the header string and trim
            var headers: [String: String] = [:]
            
            if let headerString = String(data: fullHeaderData, encoding: .utf8) {
                // Split by newlines (handle \r\n or \n)
                let lines = headerString.components(separatedBy: CharacterSet.newlines).filter { !$0.isEmpty }
                for line in lines {
                     let parts = line.split(separator: ":", maxSplits: 1).map { String($0) }
                     if parts.count == 2 {
                         headers[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
                     }
                }
            }
            
            // 4. Clean up body (remove trailing CRLF/LF if present)
            // The boundary split leaves the CRLF before the boundary at the END of this chunk
            var finalBody = bodyData
            // Check for \r\n
            if finalBody.count >= 2, finalBody.last == 10, finalBody.dropLast().last == 13 {
                 finalBody = finalBody.dropLast(2)
            } else if finalBody.count >= 1, finalBody.last == 10 { // Just \n
                 finalBody = finalBody.dropLast(1)
            }
            
            if !headers.isEmpty {
                parts.append(Part(headers: headers, body: finalBody))
            }
        }
        
        lastParseCount = parts.count
        return parts
    }
    
    // Helper to split Data
    static func split(data: Data, separator: Data) -> [Data] {
        var chunks: [Data] = []
        var searchRange: Range<Data.Index> = 0..<data.count
        
        while let foundRange = data.range(of: separator, options: [], in: searchRange) {
            if foundRange.lowerBound > searchRange.lowerBound {
                chunks.append(data.subdata(in: searchRange.lowerBound..<foundRange.lowerBound))
            }
            searchRange = foundRange.upperBound..<data.count
        }
        
        // Append last chunk if any
        if searchRange.lowerBound < data.count {
             chunks.append(data.subdata(in: searchRange))
        }
        return chunks
    }
}
