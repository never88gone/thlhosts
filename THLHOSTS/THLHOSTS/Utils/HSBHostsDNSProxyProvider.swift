
import NetworkExtension

/// DNS Proxy Provider for Hosts functionality
/// This is the recommended approach over PacketTunnelProvider for DNS/Hosts
class HSBHostsDNSProxyProvider: NEDNSProxyProvider {
    
    private var hostsMap: [String: String] = [:]
    private var upstreamDNS: String = "8.8.8.8"
    private var dnsQueue = DispatchQueue(label: "com.hsb.dnsproxy", qos: .userInitiated)
    
    override func startProxy(options: [String : Any]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("[HSBDNSProxy] Starting DNS proxy...")
        
        // 1. Load hosts configuration from shared container
        if let hostsContent = loadHostsFromSharedContainer() {
            parseHosts(content: hostsContent)
        } else if let hostsContent = options?["hosts"] as? String {
            parseHosts(content: hostsContent)
        }
        
        // 2. Configure upstream DNS
        if let upstream = options?["upstreamDNS"] as? String {
            upstreamDNS = upstream
        }
        
        // 3. Setup DNS proxy
        let settings = NEDNSSettings(servers: [upstreamDNS])
        settings.matchDomains = [""] // Match all domains
        
        completionHandler(nil)
        NSLog("[HSBDNSProxy] DNS proxy started with \(hostsMap.count) hosts rules")
    }
    
    override func stopProxy(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[HSBDNSProxy] Stopping DNS proxy, reason: \(reason.rawValue)")
        hostsMap.removeAll()
        completionHandler()
    }
    
    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        // This is called for each new DNS query
        guard let udpFlow = flow as? NEAppProxyUDPFlow else {
            return false
        }
        
        dnsQueue.async { [weak self] in
            self?.handleDNSQuery(udpFlow)
        }
        
        return true
    }
    
    // MARK: - DNS Query Handling
    
    private func handleDNSQuery(_ flow: NEAppProxyUDPFlow) {
        flow.readDatagrams { [weak self] datagrams, endpoints, error in
            guard let self = self, let datagrams = datagrams, !datagrams.isEmpty else {
                return
            }
            
            for (index, datagram) in datagrams.enumerated() {
                if let query = self.parseDNSQuery(datagram) {
                    NSLog("[HSBDNSProxy] Query for: \(query.domain)")
                    
                    // Check hosts map
                    if let customIP = self.hostsMap[query.domain] {
                        NSLog("[HSBDNSProxy] Hosts match: \(query.domain) -> \(customIP)")
                        
                        if let response = self.createDNSResponse(
                            queryID: query.id,
                            domain: query.domain,
                            ip: customIP
                        ) {
                            let endpoint = endpoints?[index]
                            flow.writeDatagrams([response], sentBy: endpoint != nil ? [endpoint!] : []) { _ in }
                            continue
                        }
                    }
                    
                    // Forward to upstream DNS
                    self.forwardToUpstream(datagram: datagram, flow: flow, endpoint: endpoints?[index])
                }
            }
            
            // Continue reading
            self.handleDNSQuery(flow)
        }
    }
    
    // MARK: - DNS Parsing
    
    private struct DNSQuery {
        let id: UInt16
        let domain: String
    }
    
    private func parseDNSQuery(_ data: Data) -> DNSQuery? {
        guard data.count > 12 else { return nil }
        
        // DNS Header: 12 bytes
        let id = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt16.self) }.bigEndian
        
        // Parse domain name from Question section
        var offset = 12
        var domain = ""
        
        while offset < data.count {
            let length = Int(data[offset])
            if length == 0 { break }
            offset += 1
            
            if offset + length > data.count { return nil }
            
            let label = String(data: data[offset..<offset+length], encoding: .utf8) ?? ""
            domain += (domain.isEmpty ? "" : ".") + label
            offset += length
        }
        
        guard !domain.isEmpty else { return nil }
        return DNSQuery(id: id, domain: domain)
    }
    
    private func createDNSResponse(queryID: UInt16, domain: String, ip: String) -> Data? {
        guard let ipComponents = parseIPv4(ip) else { return nil }
        
        var response = Data()
        
        // DNS Header (12 bytes)
        response.append(contentsOf: queryID.bigEndian.bytes) // Transaction ID
        response.append(contentsOf: [0x81, 0x80]) // Flags: Standard query response
        response.append(contentsOf: [0x00, 0x01]) // Questions: 1
        response.append(contentsOf: [0x00, 0x01]) // Answer RRs: 1
        response.append(contentsOf: [0x00, 0x00]) // Authority RRs: 0
        response.append(contentsOf: [0x00, 0x00]) // Additional RRs: 0
        
        // Question section
        response.append(encodeDomainName(domain))
        response.append(contentsOf: [0x00, 0x01]) // Type A
        response.append(contentsOf: [0x00, 0x01]) // Class IN
        
        // Answer section
        response.append(contentsOf: [0xC0, 0x0C]) // Name pointer to question
        response.append(contentsOf: [0x00, 0x01]) // Type A
        response.append(contentsOf: [0x00, 0x01]) // Class IN
        response.append(contentsOf: [0x00, 0x00, 0x00, 0x3C]) // TTL: 60 seconds
        response.append(contentsOf: [0x00, 0x04]) // Data length: 4
        response.append(contentsOf: ipComponents) // IP address
        
        return response
    }
    
    private func encodeDomainName(_ domain: String) -> Data {
        var data = Data()
        let labels = domain.split(separator: ".")
        
        for label in labels {
            let labelData = Data(label.utf8)
            data.append(UInt8(labelData.count))
            data.append(labelData)
        }
        
        data.append(0x00) // Null terminator
        return data
    }
    
    private func parseIPv4(_ ip: String) -> [UInt8]? {
        let components = ip.split(separator: ".").compactMap { UInt8($0) }
        return components.count == 4 ? components : nil
    }
    
    private func forwardToUpstream(datagram: Data, flow: NEAppProxyUDPFlow, endpoint: NWEndpoint?) {
        // Create upstream DNS endpoint
        let upstreamEndpoint = NWHostEndpoint(hostname: upstreamDNS, port: "53")
        
        // Forward query
        flow.writeDatagrams([datagram], sentBy: [upstreamEndpoint]) { error in
            if let error = error {
                NSLog("[HSBDNSProxy] Forward error: \(error)")
            }
        }
    }
    
    // MARK: - Hosts Parsing
    
    private func parseHosts(content: String) {
        hostsMap.removeAll()
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            // Remove comments
            let clean = line.components(separatedBy: "#").first ?? ""
            let parts = clean.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            
            if parts.count >= 2 {
                let ip = parts[0]
                // Support multiple domains per line
                for i in 1..<parts.count {
                    let domain = parts[i].lowercased() // DNS is case-insensitive
                    hostsMap[domain] = ip
                }
            }
        }
        
        NSLog("[HSBDNSProxy] Parsed \(hostsMap.count) hosts entries")
    }
    
    private func loadHostsFromSharedContainer() -> String? {
        // Use App Group to share data between main app and extension
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourcompany.hsbtv"
        ) else {
            NSLog("[HSBDNSProxy] Failed to access shared container")
            return nil
        }
        
        let hostsURL = containerURL.appendingPathComponent("active_hosts.txt")
        
        do {
            let content = try String(contentsOf: hostsURL, encoding: .utf8)
            NSLog("[HSBDNSProxy] Loaded hosts from shared container")
            return content
        } catch {
            NSLog("[HSBDNSProxy] No shared hosts file: \(error)")
            return nil
        }
    }
}

// MARK: - UInt16 Extension

extension UInt16 {
    var bytes: [UInt8] {
        return [UInt8(self >> 8), UInt8(self & 0xFF)]
    }
}
