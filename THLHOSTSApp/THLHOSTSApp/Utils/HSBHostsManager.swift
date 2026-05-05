
import Foundation
import Swifter
import UIKit
import NetworkExtension
import SwiftUI

@objc public class HSBHostsManager: NSObject {
    @objc public static let shared = HSBHostsManager()
    
    private var httpServer = HttpServer()
    private var started = false
    public var onReceiveHosts: ((String) -> Void)?
    
    // VPN Manager
    private var vpnManager: NETunnelProviderManager?
    private let kTunnelBundleSuffix = ".extension"
    private let kAppGroupIdentifier = "group.com.never88gone.thlhosts" // 修改为你的 App Group ID
    
    // VPN Status
    @Published public var isVPNEnabled: Bool = false
    @Published public var vpnStatus: NEVPNStatus = .invalid
    
    private override init() {
        super.init()
        // Delaying load to avoid early IPC issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadVPNManager()
        }
        observeVPNStatus()
    }
    
    // MARK: - VPN Management
    
    private func loadVPNManager() {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let providerID = bundleID + kTunnelBundleSuffix
        NSLog("HSBHostsManager: Loading VPN configs. AppID: \(bundleID), ProviderID: \(providerID)")
        
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                NSLog("HSBHostsManager: Failed to load VPN config: \(error.localizedDescription)")
                return
            }
            
            // On tvOS, we might need to be more aggressive in finding our specific manager
            let bundleID = Bundle.main.bundleIdentifier ?? ""
            let providerID = bundleID + (self?.kTunnelBundleSuffix ?? ".extension")
            
            self?.vpnManager = managers?.first(where: { manager in
                (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == providerID
            }) ?? managers?.first
            
            if let manager = self?.vpnManager {
                NSLog("HSBHostsManager: Found VPN configuration: \(manager.localizedDescription ?? "No Description")")
            } else {
                NSLog("HSBHostsManager: No VPN configuration found, will create on demand.")
            }
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
    
    public var hostsDirectory: URL {
        let fileManager = FileManager.default
        
        // 1. Try App Group (Best for all platforms with Extensions)
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) {
            let hostsDir = groupURL.appendingPathComponent("Hosts", isDirectory: true)
            if !fileManager.fileExists(atPath: hostsDir.path) {
                try? fileManager.createDirectory(at: hostsDir, withIntermediateDirectories: true, attributes: nil)
            }
            // Check if writable
            let testFile = hostsDir.appendingPathComponent(".test")
            if (try? "test".write(to: testFile, atomically: true, encoding: .utf8)) != nil {
                try? fileManager.removeItem(at: testFile)
                return hostsDir
            }
        }
        
        // 2. Try Application Support (Persistent on iOS/iPadOS)
        if let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let hostsDir = appSupportDir.appendingPathComponent("Hosts", isDirectory: true)
            if !fileManager.fileExists(atPath: hostsDir.path) {
                try? fileManager.createDirectory(at: hostsDir, withIntermediateDirectories: true, attributes: nil)
            }
            // Check if writable
            let testFile = hostsDir.appendingPathComponent(".test")
            if (try? "test".write(to: testFile, atomically: true, encoding: .utf8)) != nil {
                try? fileManager.removeItem(at: testFile)
                return hostsDir
            }
        }
        
        // 3. Last Resort: Caches (Always writable on tvOS)
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let hostsDir = cacheDir.appendingPathComponent("Hosts", isDirectory: true)
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
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            let manager = managers?.first ?? NETunnelProviderManager()
            
            // Configure protocol
            let proto = NETunnelProviderProtocol()
            let bundleID = Bundle.main.bundleIdentifier ?? "com.never88gone.thlhosts"
            proto.providerBundleIdentifier = bundleID + (self?.kTunnelBundleSuffix ?? ".extension")
            proto.serverAddress = "THLHosts"
            proto.providerConfiguration = [
                "hosts": hostsContent,
                "upstreamDNS": "8.8.8.8"
            ]
            
            manager.protocolConfiguration = proto
            manager.localizedDescription = "THLHosts"
            manager.isEnabled = true
            
            manager.saveToPreferences { [weak self] error in
                if let error = error {
                    NSLog("HSBHostsManager: Failed to save VPN config: \(error.localizedDescription)")
                    // If IPC failed, it's almost certainly a signing/entitlement issue
                    if (error as NSError).code == 5 {
                        NSLog("HSBHostsManager: CRITICAL - IPC failed. Please check tvOS Provisioning Profile and Entitlements.")
                    }
                    return
                }
                
                NSLog("HSBHostsManager: VPN configuration saved successfully")
                self?.vpnManager = manager
                self?.startVPN(hostsContent: hostsContent)
            }
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
    
    public func startServer(port: in_port_t = 8080) -> String? {
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
        httpServer.get["/"] = { _ in
            if let path = Bundle.main.path(forResource: "upload", ofType: "html"),
               let html = try? String(contentsOfFile: path) {
                return .ok(.html(html))
            }
            return .notFound()
        }
        
        httpServer.post["/upload"] = { [weak self] req in
            guard let self = self else { return .internalServerError(nil) }
            return self.handleUpload(req)
        }
    }
    
    private func handleUpload(_ req: HttpRequest) -> HttpResponse {
        let target = req.queryParams.first(where: { $0.0 == "target" })?.1
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
                    let rawName = value.trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
                    // Sanitize filename: remove illegal characters and keep only safe ones
                    filename = rawName.components(separatedBy: CharacterSet.alphanumerics.inverted.subtracting(CharacterSet(charactersIn: ".-_"))).joined()
                }
            }
            
            // Allow .hosts, .txt, or no extension
            if let fn = filename, !part.body.isEmpty {
                // If target is provided from query params, force use it as filename
                let finalFilename = target ?? fn
                return saveHostsFile(data: Data(part.body), filename: finalFilename)
            }
        }
        return .badRequest(.text("Invalid file upload"))
    }
    
    private func saveHostsFile(data: Data, filename: String) -> HttpResponse {
        // Remove activeHost fallback so it strictly uses the provided filename (target or fn)
        let actualFilename = filename
        let destURL = hostsDirectory.appendingPathComponent(actualFilename)
        
        NSLog("HSBHostsManager: Saving file to \(destURL.path)")
        
        do {
            try data.write(to: destURL, options: .atomic)
            
            // If we overwrote the active host, refresh the VPN/Proxy content
            if let active = activeHost, active == actualFilename {
                applyHostsProxy(filename: active)
                updateVPNConfiguration(filename: active)
            }
            
            DispatchQueue.main.async {
                self.onReceiveHosts?(actualFilename)
                NotificationCenter.default.post(name: NSNotification.Name("HSBHostsUploaded"), object: actualFilename)
            }
            return .ok(.text("Upload Successful! Updated: \(actualFilename)"))
        } catch {
            NSLog("HSBHostsManager: Failed to save uploaded file: \(error.localizedDescription)")
            return .internalServerError(.text("Failed to save file: \(error.localizedDescription)"))
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
    
    public func saveHostsContent(_ content: String, filename: String) {
        let url = hostsDirectory.appendingPathComponent(filename)
        try? content.write(to: url, atomically: true, encoding: .utf8)
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
    // MARK: - UI Factory
    
    @objc public func makeRootViewController() -> UIViewController {
        #if os(iOS)
        // MARK: - Global Navigation Bar Appearance (Dark Design System)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor         = UIColor(hex: "#030712")   // appBackground
        appearance.titleTextAttributes     = [.foregroundColor: UIColor(hex: "#CBD5E1")]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(hex: "#CBD5E1")]
        
        let buttonAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(hex: "#698df9")  // appCTA
        ]
        let barButtonAppearance = UIBarButtonItemAppearance()
        barButtonAppearance.normal.titleTextAttributes = buttonAttrs
        appearance.buttonAppearance = barButtonAppearance
        appearance.doneButtonAppearance = barButtonAppearance
        appearance.backButtonAppearance = barButtonAppearance
        
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
        #endif
        
        UINavigationBar.appearance().tintColor = UIColor(hex: "#698df9")
        
        return UIHostingController(rootView: MainView())
    }
}
