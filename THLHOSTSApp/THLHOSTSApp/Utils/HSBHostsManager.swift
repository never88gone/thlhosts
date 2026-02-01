
import Foundation
import Swifter
import UIKit
import NetworkExtension

@objc public class HSBHostsManager: NSObject {
    @objc public static let shared = HSBHostsManager()
    
    private var httpServer = HttpServer()
    private var started = false
    public var onReceiveHosts: ((String) -> Void)?
    
    // VPN Manager
    private var vpnManager: NETunnelProviderManager?
    private let kTunnelBundleSuffix = ".HSBHostsExtension"
    private let kAppGroupIdentifier = "group.com.hsb.tvbrowser" // 修改为你的 App Group ID
    
    // VPN Status
    @Published public var isVPNEnabled: Bool = false
    @Published public var vpnStatus: NEVPNStatus = .invalid
    
    private override init() {
        super.init()
        loadVPNManager()
        observeVPNStatus()
    }
    
    // MARK: - VPN Management
    
    private func loadVPNManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                NSLog("HSBHostsManager: Failed to load VPN config: \(error)")
                return
            }
            
            // Find existing manager or create new one
            self?.vpnManager = managers?.first
            self?.updateVPNStatus()
        }
    }
    
    private func observeVPNStatus() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }
    
    @objc private func vpnStatusDidChange(_ notification: Notification) {
        updateVPNStatus()
    }
    
    private func updateVPNStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.vpnStatus = self.vpnManager?.connection.status ?? .invalid
            self.isVPNEnabled = self.vpnStatus == .connected
            NSLog("HSBHostsManager: VPN status = \(self.vpnStatus.rawValue)")
        }
    }
    
    // MARK: - Directory Management
    
    private var hostsDirectory: URL {
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let hostsDir = docDir.appendingPathComponent("Hosts")
        if !fileManager.fileExists(atPath: hostsDir.path) {
            try? fileManager.createDirectory(at: hostsDir, withIntermediateDirectories: true, attributes: nil)
        }
        return hostsDir
    }
    
    private var sharedContainerURL: URL? {
        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: kAppGroupIdentifier
        )
    }
    
    // MARK: - Active Hosts Management
    
    private let kActiveHostsKey = "HSBActiveHostsFilename"
    
    public var activeHost: String? {
        get {
            return UserDefaults.standard.string(forKey: kActiveHostsKey)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: kActiveHostsKey)
                // 1. App内生效 (for WebView)
                applyHostsProxy(filename: value)
                // 2. 系统VPN生效 (for system-wide)
                updateVPNConfiguration(filename: value)
            } else {
                UserDefaults.standard.removeObject(forKey: kActiveHostsKey)
                disableHostsProxy()
                stopVPN()
            }
        }
    }
    
    // MARK: - VPN Configuration
    
    private func updateVPNConfiguration(filename: String) {
        guard let content = getHostsContent(filename: filename) else {
            NSLog("HSBHostsManager: Failed to read hosts file: \(filename)")
            return
        }
        
        // Copy to shared container for extension access
        copyHostsToSharedContainer(content: content)
        
        // Create or update VPN configuration
        if vpnManager == nil {
            createVPNConfiguration(hostsContent: content)
        } else {
            startVPN(hostsContent: content)
        }
    }
    
    private func createVPNConfiguration(hostsContent: String) {
        let newManager = NETunnelProviderManager()
        
        // Configure protocol
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = Bundle.main.bundleIdentifier! + kTunnelBundleSuffix
        proto.serverAddress = "Smart DNS Proxy"
        proto.providerConfiguration = [
            "hosts": hostsContent,
            "upstreamDNS": "8.8.8.8"
        ]
        
        newManager.protocolConfiguration = proto
        newManager.localizedDescription = "HSB Hosts Manager"
        newManager.isEnabled = true
        
        newManager.saveToPreferences { [weak self] error in
            if let error = error {
                NSLog("HSBHostsManager: Failed to save VPN config: \(error)")
                return
            }
            
            NSLog("HSBHostsManager: VPN configuration saved")
            self?.vpnManager = newManager
            self?.startVPN(hostsContent: hostsContent)
        }
    }
    
    private func startVPN(hostsContent: String) {
        guard let manager = vpnManager else { return }
        
        // Update configuration
        if let proto = manager.protocolConfiguration as? NETunnelProviderProtocol {
            proto.providerConfiguration?["hosts"] = hostsContent as NSObject
        }
        
        manager.saveToPreferences { [weak self] error in
            if let error = error {
                NSLog("HSBHostsManager: Failed to update VPN config: \(error)")
                return
            }
            
            manager.loadFromPreferences { error in
                if let error = error {
                    NSLog("HSBHostsManager: Failed to reload VPN config: \(error)")
                    return
                }
                
                do {
                    try manager.connection.startVPNTunnel()
                    NSLog("HSBHostsManager: VPN tunnel started")
                } catch {
                    NSLog("HSBHostsManager: Failed to start VPN: \(error)")
                }
            }
        }
    }
    
    private func stopVPN() {
        guard let manager = vpnManager else { return }
        manager.connection.stopVPNTunnel()
        NSLog("HSBHostsManager: VPN tunnel stopped")
    }
    
    private func copyHostsToSharedContainer(content: String) {
        guard let containerURL = sharedContainerURL else {
            NSLog("HSBHostsManager: Failed to access shared container")
            return
        }
        
        let hostsURL = containerURL.appendingPathComponent("active_hosts.txt")
        
        do {
            try content.write(to: hostsURL, atomically: true, encoding: .utf8)
            NSLog("HSBHostsManager: Copied hosts to shared container")
        } catch {
            NSLog("HSBHostsManager: Failed to copy hosts: \(error)")
        }
    }
    
    // MARK: - Server Logic
    
    public func startServer(port: in_port_t = 9971) -> String? {
        if started { stopServer() }
        
        setupRoutes()
        
        do {
            try httpServer.start(port)
            started = true
            return getLocalIPAddress()
        } catch {
            print("HSBHostsManager start server failed: \(error)")
            return nil
        }
    }
    
    public func stopServer() {
        httpServer.stop()
        started = false
    }
    
    private func setupRoutes() {
        httpServer.get["/"] = { [weak self] _ in
            guard let self = self else { return .internalServerError(nil) }
            return .ok(.html(self.uploadHtml))
        }
        
        httpServer.post["/upload"] = { [weak self] req in
            guard let self = self else { return .internalServerError(nil) }
            return self.handleUpload(req)
        }
    }
    
    private func handleUpload(_ req: HttpRequest) -> HttpResponse {
        let parts = req.parseMultiPartFormData()
        for part in parts {
            let disposition = part.headers["Content-Disposition"] ?? part.headers["content-disposition"]
            guard let params = disposition else { continue }
            
            var filename: String?
            let attributes = params.components(separatedBy: ";")
            for attribute in attributes {
                let trimmed = attribute.trimmingCharacters(in: .whitespaces)
                if trimmed.lowercased().hasPrefix("filename=") {
                    let value = String(trimmed.dropFirst("filename=".count))
                    filename = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }
            }
            
            // Allow .hosts, .txt, or no extension
            if let fn = filename, !part.body.isEmpty {
                // Ensure it ends with .hosts if user didn't specify extension relevantly?
                // Actually, let's keep original name but standardizing could be good.
                // But user wants "hosts文件", usually just "hosts" or "example.hosts"
                return saveHostsFile(data: Data(part.body), filename: fn)
            }
        }
        return .badRequest(.text("Invalid file upload"))
    }
    
    private func saveHostsFile(data: Data, filename: String) -> HttpResponse {
        let destURL = hostsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: destURL)
            DispatchQueue.main.async {
                self.onReceiveHosts?(filename)
            }
            return .ok(.text("Upload Successful! Filename: \(filename)"))
        } catch {
            return .internalServerError(.text("Save failed: \(error)"))
        }
    }
    
    // MARK: - File Management
    
    public func listHostsFiles() -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: hostsDirectory.path)
            return files.filter { !$0.hasPrefix(".") }.sorted()
        } catch {
            return []
        }
    }
    
    public func getHostsContent(filename: String) -> String? {
        let url = hostsDirectory.appendingPathComponent(filename)
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    public func deleteHostsFile(filename: String) {
        let url = hostsDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        if activeHost == filename {
            activeHost = nil
        }
    }
    
    // MARK: - Hosts Parsing & Logic
    
    private var hostsMap: [String: String] = [:]
    private let hostsQueue = DispatchQueue(label: "com.hsbtvbox.hosts.queue", attributes: .concurrent)
    
    private func applyHostsProxy(filename: String) {
        hostsQueue.async(flags: .barrier) {
            self.hostsMap.removeAll()
            guard let content = self.getHostsContent(filename: filename) else { return }
            
            print("HSBHostsManager: Loading hosts from \(filename)...")
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                // Remove comments (#)
                let cleanLine = line.components(separatedBy: "#").first ?? ""
                // Split by whitespace
                let parts = cleanLine.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                
                if parts.count >= 2 {
                    let ip = parts[0]
                    // Support multiple domains per line: 127.0.0.1 localhost otherhost
                    for i in 1..<parts.count {
                        let domain = parts[i]
                        self.hostsMap[domain] = ip
                    }
                }
            }
            print("HSBHostsManager: Loaded \(self.hostsMap.count) rules.")
        }
    }
    
    private func disableHostsProxy() {
        hostsQueue.async(flags: .barrier) {
            self.hostsMap.removeAll()
            print("HSBHostsManager: Hosts disabled.")
        }
    }
    
    /// Check if a domain has a custom IP rule
    /// - Parameter domain: The hostname (e.g., "google.com")
    /// - Returns: The mapped IP address, or nil if not found.
    public func resolveIP(for domain: String) -> String? {
        return hostsQueue.sync {
            return hostsMap[domain]
        }
    }
    
    /// Transforms a standard URL into a URLRequest with IP replacement and Host header manually set.
    /// Use this when loading AVPlayer or Alamofire requests.
    /// - Parameter url: Original URL (e.g. http://my-site.com/video.m3u8)
    /// - Returns: A URLRequest pointing to the IP (http://1.2.3.4/video.m3u8) with "Host: my-site.com" header.
    ///            Returns original request if no rule matches.
    public func transform(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        guard let host = url.host,
              let ip = resolveIP(for: host) else {
            return request
        }
        
        // 1. Replace Host with IP in URL
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.host = ip
        
        if let newURL = components?.url {
            request.url = newURL
            // 2. Set the original Host in header
            request.setValue(host, forHTTPHeaderField: "Host")
            print("HSBHostsManager: Redirected \(host) -> \(ip)")
        }
        
        return request
    }
    
    // MARK: - Utils
    
    private var uploadHtml: String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Upload Hosts File</title>
            <style>
                body { font-family: -apple-system, sans-serif; text-align: center; padding: 50px; background: #f0f0f0; }
                .container { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 500px; margin: 0 auto; }
                h1 { color: #333; }
                .btn { display: inline-block; padding: 15px 30px; background: #007aff; color: white; border-radius: 10px; text-decoration: none; font-weight: bold; cursor: pointer; border: none; font-size: 18px; margin-top: 20px; }
                input[type=file] { display: none; }
                .file-label { display: block; padding: 40px; border: 2px dashed #ddd; border-radius: 10px; margin: 20px 0; color: #666; cursor: pointer; }
                .file-label:hover { border-color: #007aff; background: #f8faff; color: #007aff; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Upload Hosts File</h1>
                <p>Select a hosts file to upload to your TV.</p>
                <form action="/upload" method="post" enctype="multipart/form-data">
                    <label class="file-label">
                        <input type="file" name="file" onchange="this.form.submit()">
                        <span>Click to Select File</span>
                    </label>
                </form>
            </div>
        </body>
        </html>
        """
    }
    
    private func getLocalIPAddress() -> String? {
        var ipv4Address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    if name == "lo0" { continue }
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    let ip = String(cString: hostname)
                    if name == "en0" { ipv4Address = ip; break }
                    if ipv4Address == nil { ipv4Address = ip }
                }
            }
            freeifaddrs(ifaddr)
        }
        return ipv4Address
    }
}
