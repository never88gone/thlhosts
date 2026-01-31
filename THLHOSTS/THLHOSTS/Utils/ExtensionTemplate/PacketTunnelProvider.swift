
import NetworkExtension
import Foundation

// MARK: - PacketTunnelProvider

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var session: NWUDPSession?
    private var hostsMap: [String: String] = [:]
    
    // 真实 DNS 服务器 (114.114.114.114 or 8.8.8.8)
    private let realDNSServer = NWHostEndpoint(hostname: "114.114.114.114", port: "53")
    
    // 虚拟网关地址
    private let vpnIP = "198.18.0.1"
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // 1. 加载 Hosts
        if let conf = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration,
           let hostsContent = conf["hosts"] as? String {
            parseHosts(content: hostsContent)
        }
        
        // 2. 创建 UDP Session 用于转发非 Hosts 的 DNS 请求
        self.session = self.createUDPSession(to: realDNSServer, from: nil)
        self.session?.setReadHandler({ [weak self] (packets, error) in
            guard let self = self, let packets = packets else { return }
            // 收到真实 DNS 回包 -> 转发回系统
            self.packetFlow.writePackets(packets, withProtocols: [NSNumber(value: AF_INET)])
        }, maxDatagrams: 100)
        
        // 3. 配置网络设置
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1400
        
        // 路由设置：只拦截发往虚拟 DNS 的流量 (或者拦截全部)
        // 为了稳定，我们通常拦截全部 DNS，把 DNS Server 指向我们自己 (VPN IP)
        let ipv4Settings = NEIPv4Settings(addresses: [vpnIP], subnetMasks: ["255.255.255.255"])
        // 这里为了简单，我们加上 default route，接管所有流量
        // 但为了性能，其实只接管 DNS 最好。不过 iOS/tvOS VPN 对 split tunnel 支持有限。
        // 我们尝试只接管 DNS。
        // 方法：将 DNS 服务器设为 VPN IP，同时 includedRoutes 只包含 VPN IP (或 0.0.0.0/0 看需求)
        // 最稳妥方案：全量接管
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        // DNS 设置：指向 VPN 自身 IP
        let dnsSettings = NEDNSSettings(servers: [vpnIP])
        dnsSettings.matchDomains = [""] // 捕获所有域名
        settings.dnsSettings = dnsSettings
        
        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                completionHandler(error)
            } else {
                // 启动循环读取
                self?.readPackets()
                completionHandler(nil)
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        session?.cancel()
        completionHandler()
    }
    
    // MARK: - Core Loop
    
    private func readPackets() {
        packetFlow.readPackets { [weak self] (packets, protocols) in
            guard let self = self else { return }
            
            for (i, packet) in packets.enumerated() {
                // 暂时只处理 IPv4 (AF_INET = 2)
                if protocols[i].intValue == AF_INET {
                    self.handleIPv4Packet(packet)
                } 
                // IPv6 略
            }
            
            // 递归读取
            self.readPackets()
        }
    }
    
    private func handleIPv4Packet(_ packet: Data) {
        // 简易 IP Header 解析
        // IP Header (20 bytes) + UDP Header (8 bytes) = 28 bytes offset to Data
        guard packet.count > 28 else { return }
        
        // 检查 Protocol 是否为 UDP (17)
        let proto = packet[9]
        guard proto == 17 else { return } // 17 = UDP
        
        // 获取 Header 长度 (IHL)
        let versionAndHeaderLen = packet[0]
        let headerLen = Int((versionAndHeaderLen & 0x0F) * 4)
        
        // 解析 UDP 目标端口
        // UDP Header starts at headerLen
        // Source Port (2) | Dest Port (2) | Length (2) | Checksum (2)
        let destPortBytes = packet[(headerLen + 2)..<(headerLen + 4)]
        let destPort = UInt16(destPortBytes[destPortBytes.startIndex]) << 8 | UInt16(destPortBytes[destPortBytes.startIndex + 1])
        
        // 如果是发往 53 端口 (DNS)
        if destPort == 53 {
            let dnsPayloadFn = headerLen + 8
            let dnsData = packet.subdata(in: dnsPayloadFn..<packet.count)
            
            // 尝试解析 Hostname
            if let result = SimpleDNSParser.parseHeaderAndQuery(dnsData) {
                let domain = result.domain
                let txId = result.txId
                
                // 检查 Hosts
                if let targetIP = self.hostsMap[domain] {
                    // HIT! 构造伪造响应
                    if let response = SimpleDNSBuilder.buildResponse(originalData: dnsData, txId: txId, domain: domain, answerIP: targetIP) {
                        // 封装回 IP/UDP 包
                        let responsePacket = PacketBuilder.buildUDPResponse(originalPacket: packet, payload: response, srcIP: self.vpnIP)
                        self.packetFlow.writePackets([responsePacket], withProtocols: [NSNumber(value: AF_INET)])
                        // NSLog("Configured Extension: Resolved \(domain) -> \(targetIP)")
                        return
                    }
                }
            }
            
            // MISS! 转发给真实 DNS
            // 注意：这里简单地 writeDatagram 给 UDPSession
            self.session?.writeDatagram(dnsData, completionHandler: { error in
                if let error = error {
                    print("Forward Error: \(error)")
                }
            })
        }
    }

    private func parseHosts(content: String) {
        hostsMap.removeAll()
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let clean = line.components(separatedBy: "#").first ?? ""
            let parts = clean.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            if parts.count >= 2 {
                let ip = parts[0]
                for i in 1..<parts.count {
                    hostsMap[parts[i]] = ip
                }
            }
        }
        NSLog("Hosts Loaded: \(hostsMap.count) entries")
    }
}

// MARK: - Simple DNS Helpers

struct SimpleDNSParser {
    static func parseHeaderAndQuery(_ data: Data) -> (txId: UInt16, domain: String)? {
        guard data.count > 12 else { return nil }
        
        // Transaction ID (Bytes 0-1)
        let txId = UInt16(data[0]) << 8 | UInt16(data[1])
        
        // Flags (2-3), QDCOUNT (4-5)...
        // Question starts at 12
        var offset = 12
        var domainParts: [String] = []
        
        while offset < data.count {
            let len = Int(data[offset])
            if len == 0 { break } // End of name
            if (len & 0xC0) == 0xC0 { return nil } // Compression pointer not supported in query usually
            
            offset += 1
            guard offset + len <= data.count else { return nil }
            if let part = String(data: data.subdata(in: offset..<(offset + len)), encoding: .ascii) {
                domainParts.append(part)
            }
            offset += len
        }
        
        if domainParts.isEmpty { return nil }
        return (txId, domainParts.joined(separator: "."))
    }
}

struct SimpleDNSBuilder {
    static func buildResponse(originalData: Data, txId: UInt16, domain: String, answerIP: String) -> Data? {
        var response = Data()
        
        // 1. Header (12 bytes)
        // TxID copy
        response.append(originalData.subdata(in: 0..<2))
        
        // Flags: Standard Response, No Error (0x8180)
        // QR=1, Opcode=0, AA=0, TC=0, RD=1 | RA=1, Z=0, RCODE=0
        response.append(contentsOf: [0x81, 0x80])
        
        // QDCOUNT (Questions): 1
        response.append(activeBytes: originalData.subdata(in: 4..<6)) // copy original QDCount (usually 1)
        // ANCOUNT (Answers): 1
        response.append(contentsOf: [0x00, 0x01])
        // NSCOUNT: 0
        response.append(contentsOf: [0x00, 0x00])
        // ARCOUNT: 0
        response.append(contentsOf: [0x00, 0x00])
        
        // 2. Question Section (Copy from original usually safest)
        // Find end of Question
        var qEnd = 12
        while qEnd < originalData.count {
            let len = Int(originalData[qEnd])
            if len == 0 {
                qEnd += 1 + 4 // +1 for root null, +2 (QTYPE), +2 (QCLASS)
                break
            }
            qEnd += 1 + len
        }
        if qEnd > originalData.count { return nil }
        response.append(originalData.subdata(in: 12..<qEnd))
        
        // 3. Answer Section
        // Name Pointer to start of packet (0xC00C = 1100 0000 0000 1100 = Pointer to 12)
        response.append(contentsOf: [0xC0, 0x0C])
        
        // Type A (1)
        response.append(contentsOf: [0x00, 0x01])
        // Class IN (1)
        response.append(contentsOf: [0x00, 0x01])
        // TTL (60s)
        response.append(contentsOf: [0x00, 0x00, 0x00, 0x3C])
        // RDLENGTH (4 bytes for IPv4)
        response.append(contentsOf: [0x00, 0x04])
        
        // RDATA (The IP)
        let parts = answerIP.components(separatedBy: ".").compactMap { UInt8($0) }
        guard parts.count == 4 else { return nil }
        response.append(contentsOf: parts)
        
        return response
    }
}

struct PacketBuilder {
    // 这是一个极简的 IP/UDP 包构建器，用于把 UDP Payload 包装成 OS 可识别的 IP 包
    static func buildUDPResponse(originalPacket: Data, payload: Data, srcIP: String) -> Data {
        // 解析原始 IP 头以获取 src/dst IP 和 Port，然后通过交换 src/dst 来构建响应
        
        // 假设 Standard IPv4 Header (20 bytes)
        let headerLen = 20 // 简单假设，严谨应读取 IHL
        
        let srcIPRange = 12..<16
        let dstIPRange = 16..<20
        
        let originalSrcIP = originalPacket.subdata(in: srcIPRange)
        // let originalDstIP = originalPacket.subdata(in: dstIPRange) // This was us
        
        let udpHeaderOffset = headerLen
        let srcPortRange = udpHeaderOffset..<(udpHeaderOffset+2)
        let dstPortRange = (udpHeaderOffset+2)..<(udpHeaderOffset+4)
        
        let originalSrcPort = originalPacket.subdata(in: srcPortRange)
        // let originalDstPort = originalPacket.subdata(in: dstPortRange) // 53
        
        // --- Build New IP Header ---
        var ipHeader = Data()
        // Version(4) + IHL(5) = 0x45
        ipHeader.append(0x45)
        // TOS
        ipHeader.append(0x00)
        // Total Length (20 IP + 8 UDP + payload)
        let totalLen = UInt16(20 + 8 + payload.count)
        ipHeader.append(contentsOf: [UInt8(totalLen >> 8), UInt8(totalLen & 0xFF)])
        // ID
        ipHeader.append(contentsOf: [0x00, 0x00])
        // Flags/Offset
        ipHeader.append(contentsOf: [0x00, 0x00])
        // TTL
        ipHeader.append(0x40) // 64
        // Protocol (17 UDP)
        ipHeader.append(17)
        // Checksum (Zero for now, OS usually ignores or handles offload, but better calculate)
        ipHeader.append(contentsOf: [0x00, 0x00])
        
        // Source IP: Our Server IP (Virtual IP)
        // Or better: The specific IP user sent TO?
        // Actually for DNS, client expects reply from the IP it sent to.
        // In the original packet, DstIP might be 198.18.0.1. So we use that as Src.
        // Let's parse srcIP string to bytes
        let srcIPBytes = srcIP.components(separatedBy: ".").compactMap { UInt8($0) }
        ipHeader.append(contentsOf: srcIPBytes)
        
        // Dest IP: The Original Sender
        ipHeader.append(originalSrcIP)
        
        // Checksum Calculation (Optional for local tunnel sometimes, but correct to do)
        // Skipping proper IP checksum for brevity, often works in tunnel.
        // To be safe: [0x00, 0x00] usually works if validation execution is lax or hardware offloaded.
        
        // --- Build UDP Header ---
        var udpHeader = Data()
        // Src Port: 53 (Original Dest)
        udpHeader.append(contentsOf: [0x00, 0x35]) 
        // Dst Port: Original Src
        udpHeader.append(originalSrcPort)
        // Length
        let udpLen = UInt16(8 + payload.count)
        udpHeader.append(contentsOf: [UInt8(udpLen >> 8), UInt8(udpLen & 0xFF)])
        // Checksum (Can be zero)
        udpHeader.append(contentsOf: [0x00, 0x00])
        
        var fullPacket = Data()
        fullPacket.append(ipHeader)
        fullPacket.append(udpHeader)
        fullPacket.append(payload)
        
        return fullPacket
    }
}

extension Data {
    mutating func append(activeBytes data: Data) {
        self.append(data)
    }
}
