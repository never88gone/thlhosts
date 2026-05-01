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
                HStack(spacing: UIDevice.current.userInterfaceIdiom == .tv ? 40 : 16) {
                    VStack(alignment: .leading, spacing: UIDevice.current.userInterfaceIdiom == .tv ? 12 : 6) {
                        Text(file.name)
                            .font(UIDevice.current.userInterfaceIdiom == .tv ? .system(size: 64, weight: .bold) : .title2.bold())
                            .foregroundColor(.appText)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(file.isEnabled ? Color.appSuccess : Color.appMutedText)
                                .frame(width: UIDevice.current.userInterfaceIdiom == .tv ? 12 : 8)
                            Text(file.isEnabled ? "system_active".localized : "system_inactive".localized)
                                .font(UIDevice.current.userInterfaceIdiom == .tv ? .headline : .subheadline)
                                .foregroundColor(file.isEnabled ? .appSuccess : .appSubText)
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
                    HStack {
                        Label("hosts_content".localized, systemImage: "curlybraces")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Show "Fetch from URL" if content looks like a URL
                        if content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("http") {
                            Button(action: {
                                viewModel.fetchHostsFromURL(url: content, for: file) { success in
                                    if success {
                                        // Refresh local state if needed
                                        self.content = viewModel.hostsFiles.first(where: { $0.id == file.id })?.content ?? content
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "icloud.and.arrow.down")
                                    Text("fetch_url".localized)
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.appCTA)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.appCTA.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
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
                        .foregroundColor(.appText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 350)
                        .padding(8)
                        .background(Color.appSecondary.opacity(0.5))
                        .glassBackground(cornerRadius: 16)
                        .onChange(of: content) { newValue in
                            viewModel.updateContent(for: file, content: newValue)
                        }
                    #endif
                }
                
                #if os(tvOS)
                // QR Code for uploading - Only needed on TV
                VStack(spacing: 24) {
                    Label("scan_to_upload".localized, systemImage: "qrcode.viewfinder")
                        .font(.headline)
                        .foregroundColor(.appText)
                    
                    VStack(spacing: 20) {
                        if let qrImage = generateQRCode(from: "http://\(viewModel.serverIP):8080") {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding(25)
                                .background(Color.white)
                                .cornerRadius(20)
                        }
                        
                        Text("http://\(viewModel.serverIP):8080")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.appCTA)
                    }
                    .padding(32)
                    .glassBackground(cornerRadius: 32)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
                #endif
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
