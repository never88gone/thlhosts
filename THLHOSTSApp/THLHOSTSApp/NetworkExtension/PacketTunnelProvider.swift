
import NetworkExtension
import Swifter

class PacketTunnelProvider: NEPacketTunnelProvider {

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let conf = (self.protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration
        let hosts = conf?["hosts"] as? String ?? ""
        let upstreamDNS = conf?["upstreamDNS"] as? String ?? "8.8.8.8"
        
        NSLog("PacketTunnelProvider: Starting with hosts length: \(hosts.count)")
        
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1500
        
        // DNS Settings
        // We set the DNS to the upstream but we can also set matchDomains 
        // to force queries through this tunnel.
        let dnsSettings = NEDNSSettings(servers: [upstreamDNS])
        dnsSettings.matchDomains = [""] // Intercept all DNS
        settings.dnsSettings = dnsSettings
        
        // IPv4 Settings
        // To intercept DNS packets (UDP 53), we usually need to route the DNS server's IP through the tunnel
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.1"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings
        
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                NSLog("PacketTunnelProvider: Failed to set settings: \(error)")
            } else {
                NSLog("PacketTunnelProvider: Settings applied successfully")
            }
            completionHandler(error)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Add code here to start the process of stopping the tunnel.
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Handle messages from the host app
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        // Add code here to get ready to sleep.
        completionHandler()
    }

    override func wake() {
        // Add code here to wake up.
    }
}
