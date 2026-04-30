import SwiftUI
import CoreImage.CIFilterBuiltins

struct HostsDetailView: View {
    @ObservedObject var viewModel: HostsViewModel
    let file: HostsFile
    
    @State private var content: String = ""
    @State private var serverIP: String = "localhost"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header info
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .foregroundColor(.appText)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(file.isEnabled ? Color.appCTA : Color.appMutedText)
                                .frame(width: 8, height: 8)
                            Text(file.isEnabled ? "System Active" : "Configuration Inactive")
                                .font(.subheadline)
                                .foregroundColor(file.isEnabled ? .appCTA : .appMutedText)
                        }
                    }
                    Spacer()
                    
                    if file.isEnabled {
                        Image(systemName: "shield.check.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.appCTA)
                            .font(.system(size: 48))
                    }
                }
                .padding(.horizontal, 4)
                
                // Editor
                VStack(alignment: .leading, spacing: 12) {
                    Label("Hosts Content", systemImage: "curlybraces")
                        .font(.headline)
                        .foregroundColor(.appText)
                    
                    #if os(tvOS)
                    ScrollView {
                        Text(content)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(minHeight: 350)
                    .glassBackground(cornerRadius: 16)
                    #else
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 350)
                        .padding(8)
                        .background(Color.appPrimary.opacity(0.5))
                        .glassBackground(cornerRadius: 16)
                        .onChange(of: content) { newValue in
                            viewModel.updateContent(for: file, content: newValue)
                        }
                    #endif
                }
                
                // QR Code for uploading
                VStack(spacing: 16) {
                    Label("Quick Remote Upload", systemImage: "qrcode.viewfinder")
                        .font(.headline)
                        .foregroundColor(.appText)
                    
                    VStack(spacing: 16) {
                        if let qrImage = generateQRCode(from: "http://\(serverIP):8080/?name=\(file.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appCTA.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Text("Connect to http://\(serverIP):8080")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.appMutedText)
                    }
                    .padding(24)
                    .glassBackground(cornerRadius: 20)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            self.content = file.content
            // Get IP from manager
            self.serverIP = getWiFiAddress() ?? "localhost"
        }
    }
    
    // MARK: - Helpers
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
    
    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name == "en1" {
                         var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                         getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                         address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
