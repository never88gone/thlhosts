import NetworkExtension
import Network

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var hostsDict: [String: String] = [:]
    private var upstreamDNS: String = "114.114.114.114"
    private var isTunnelRunning = false

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let conf = (self.protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration
        let hostsString = conf?["hosts"] as? String ?? ""
        let dns = conf?["upstreamDNS"] as? String ?? "114.114.114.114"
        if !dns.isEmpty { self.upstreamDNS = dns }
        
        parseHosts(hostsString)
        
        // 我们充当本地 DNS 代理，虚拟 IP 设为 10.0.0.1
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.0.0.1")
        settings.mtu = 1500
        
        // 强制系统将 DNS 请求发给我们的虚拟 IP
        let dnsSettings = NEDNSSettings(servers: ["10.0.0.1"])
        dnsSettings.matchDomains = [""] // 拦截所有域名的解析
        settings.dnsSettings = dnsSettings
        
        // 关键路由配置：仅把发往 10.0.0.1 的流量吸入隧道，防止全局断网
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.255"])
        ipv4Settings.includedRoutes = [NEIPv4Route(destinationAddress: "10.0.0.1", subnetMask: "255.255.255.255")]
        settings.ipv4Settings = ipv4Settings
        
        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                completionHandler(error)
                return
            }
            self?.isTunnelRunning = true
            self?.readPacketsLoop()
            completionHandler(nil)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        isTunnelRunning = false
        completionHandler()
    }
    
    // MARK: - Core Logic
    
    private func parseHosts(_ text: String) {
        hostsDict.removeAll()
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let cleanLine = line.components(separatedBy: "#").first!.trimmingCharacters(in: .whitespaces)
            if cleanLine.isEmpty { continue }
            let parts = cleanLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 2 {
                let ip = parts[0]
                for domain in parts.dropFirst() {
                    hostsDict[domain.lowercased()] = ip
                }
            }
        }
        NSLog("PacketTunnelProvider: 已加载 \(hostsDict.count) 条 Hosts 记录")
    }
    
    private func readPacketsLoop() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self, self.isTunnelRunning else { return }
            
            for (index, packet) in packets.enumerated() {
                let proto = protocols[index].int32Value
                if proto == AF_INET {
                    self.handleIPv4Packet(packet)
                }
            }
            // 持续循环读取
            self.readPacketsLoop()
        }
    }
    
    private func handleIPv4Packet(_ packet: Data) {
        guard packet.count > 20 else { return }
        
        let versionAndIHL = packet[0]
        guard versionAndIHL >> 4 == 4 else { return } // 必须是 IPv4
        let ihl = Int(versionAndIHL & 0x0F) * 4
        guard packet.count >= ihl + 8 else { return }
        
        let protocolType = packet[9]
        guard protocolType == 17 else { return } // 必须是 UDP (17)
        
        let srcIP = packet.subdata(in: 12..<16)
        let dstIP = packet.subdata(in: 16..<20)
        
        let udpStart = ihl
        let srcPort = UInt16(packet[udpStart]) << 8 | UInt16(packet[udpStart+1])
        let dstPort = UInt16(packet[udpStart+2]) << 8 | UInt16(packet[udpStart+3])
        
        guard dstPort == 53 else { return } // 仅拦截 DNS 查询 (Port 53)
        
        let payloadStart = udpStart + 8
        let payload = packet.subdata(in: payloadStart..<packet.count)
        
        processDNSQuery(payload: payload, srcIP: srcIP, srcPort: srcPort, dstIP: dstIP, dstPort: dstPort)
    }
    
    private func processDNSQuery(payload: Data, srcIP: Data, srcPort: UInt16, dstIP: Data, dstPort: UInt16) {
        guard payload.count > 12 else { return }
        
        // 提取被查询的域名
        var domain = ""
        var i = 12
        while i < payload.count {
            let len = Int(payload[i])
            if len == 0 {
                i += 1
                break
            }
            if len >= 192 {
                i += 2 // 遇到压缩指针，终止
                break
            }
            i += 1
            if i + len <= payload.count {
                let label = String(decoding: payload.subdata(in: i..<i+len), as: UTF8.self)
                domain += label + "."
            }
            i += len
        }
        if domain.hasSuffix(".") { domain.removeLast() }
        let qDomain = domain.lowercased()
        
        // 匹配 Hosts
        if let targetIP = hostsDict[qDomain] {
            NSLog("PacketTunnelProvider: 命中 Hosts! \(qDomain) -> \(targetIP)")
            if let response = buildDNSResponse(query: payload, ipString: targetIP) {
                injectPacket(payload: response, srcIP: dstIP, srcPort: dstPort, dstIP: srcIP, dstPort: srcPort)
            }
        } else {
            // 未命中，使用真实 DNS 转发
            forwardDNSQuery(payload: payload, srcIP: srcIP, srcPort: srcPort, dstIP: dstIP, dstPort: dstPort)
        }
    }
    
    private func forwardDNSQuery(payload: Data, srcIP: Data, srcPort: UInt16, dstIP: Data, dstPort: UInt16) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(upstreamDNS), port: 53)
        let connection = NWConnection(to: endpoint, using: .udp)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: payload, completion: .contentProcessed({ _ in }))
                connection.receiveMessage { [weak self] content, _, _, _ in
                    if let content = content {
                        // 收到真实的 DNS 解析结果，封包后返回给系统
                        self?.injectPacket(payload: content, srcIP: dstIP, srcPort: dstPort, dstIP: srcIP, dstPort: srcPort)
                    }
                    connection.cancel()
                }
            case .failed(_), .cancelled:
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .global())
    }
    
    private func injectPacket(payload: Data, srcIP: Data, srcPort: UInt16, dstIP: Data, dstPort: UInt16) {
        var packet = Data(count: 20 + 8 + payload.count)
        
        // IPv4 Header
        packet[0] = 0x45
        packet[1] = 0x00
        let totalLen = UInt16(packet.count).bigEndian
        withUnsafeBytes(of: totalLen) { packet.replaceSubrange(2..<4, with: $0) }
        packet[8] = 64 // TTL
        packet[9] = 17 // UDP
        packet.replaceSubrange(12..<16, with: srcIP)
        packet.replaceSubrange(16..<20, with: dstIP)
        
        // 计算 IPv4 校验和
        var sum: UInt32 = 0
        for i in stride(from: 0, to: 20, by: 2) {
            if i == 10 { continue }
            let word = (UInt32(packet[i]) << 8) + UInt32(packet[i+1])
            sum += word
        }
        while (sum >> 16) != 0 {
            sum = (sum & 0xFFFF) + (sum >> 16)
        }
        let checksum = ~UInt16(sum)
        withUnsafeBytes(of: checksum.bigEndian) { packet.replaceSubrange(10..<12, with: $0) }
        
        // UDP Header
        let udpStart = 20
        var sp = srcPort.bigEndian
        withUnsafeBytes(of: sp) { packet.replaceSubrange(udpStart..<udpStart+2, with: $0) }
        var dp = dstPort.bigEndian
        withUnsafeBytes(of: dp) { packet.replaceSubrange(udpStart+2..<udpStart+4, with: $0) }
        let udpLen = UInt16(8 + payload.count).bigEndian
        withUnsafeBytes(of: udpLen) { packet.replaceSubrange(udpStart+4..<udpStart+6, with: $0) }
        
        // Payload
        packet.replaceSubrange(28..<packet.count, with: payload)
        
        // 塞回虚拟网卡
        packetFlow.writePackets([packet], withProtocols: [NSNumber(value: AF_INET)])
    }
    
    private func buildDNSResponse(query: Data, ipString: String) -> Data? {
        guard query.count >= 12 else { return nil }
        
        var ipBytes: [UInt8] = []
        let parts = ipString.components(separatedBy: ".")
        if parts.count == 4 {
            for part in parts {
                if let b = UInt8(part) { ipBytes.append(b) }
            }
        }
        guard ipBytes.count == 4 else { return nil }
        
        var response = query
        // Flags: QR=1(Response), AA=0, TC=0, RD=1, RA=1, RCODE=0 -> 0x8180
        response[2] = 0x81
        response[3] = 0x80
        
        // ANCOUNT = 1
        response[6] = 0x00
        response[7] = 0x01
        
        // Answer RRs
        response.append(contentsOf: [0xC0, 0x0C]) // 域名指针，指回 Question
        response.append(contentsOf: [0x00, 0x01]) // Type: A
        response.append(contentsOf: [0x00, 0x01]) // Class: IN
        response.append(contentsOf: [0x00, 0x00, 0x00, 0x3C]) // TTL: 60
        response.append(contentsOf: [0x00, 0x04]) // Data Length: 4
        response.append(contentsOf: ipBytes) // IP Bytes
        
        return response
    }
}
