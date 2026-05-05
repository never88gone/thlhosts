import SwiftUI
import CoreImage.CIFilterBuiltins

struct HostsDetailView: View {
    @ObservedObject var viewModel: HostsViewModel
    let file: HostsFile
    
    @State private var content: String = ""
    @State private var serverIP: String = "localhost"
    @State private var showingURLAlert = false
    @State private var updateURL = ""
    @State private var showingImporter = false
    private var isTV: Bool {
        #if os(tvOS)
        return true
        #else
        return false
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header info
                HStack(spacing: isTV ? 40 : 16) {
                    VStack(alignment: .leading, spacing: isTV ? 12 : 6) {
                        Text(file.name)
                            .font(isTV ? .system(size: 64, weight: .bold) : .title2.bold())
                            .foregroundColor(.appText)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(file.isEnabled ? Color.appSuccess : Color.appMutedText)
                                .frame(width: isTV ? 12 : 8)
                            Text(file.isEnabled ? "system_active".localized : "system_inactive".localized)
                                .font(isTV ? .headline : .subheadline)
                                .foregroundColor(file.isEnabled ? .appSuccess : .appSubText)
                        }
                    }
                    Spacer()
                    
                    #if os(tvOS)
                    Button(action: {
                        updateURL = file.sourceURL ?? ""
                        showingURLAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                            Text("update_from_url".localized)
                        }
                    }
                    #endif
                    
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
        .onChange(of: file.content) { newValue in
            // Refresh content if it changed externally (e.g., via import)
            if self.content != newValue {
                self.content = newValue
            }
        }
        .toolbar {
            #if os(iOS) || os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingImporter = true }) {
                        Label("import_local_file".localized, systemImage: "folder")
                    }
                    Button(action: {
                        updateURL = file.sourceURL ?? ""
                        showingURLAlert = true 
                    }) {
                        Label("update_from_url".localized, systemImage: "link")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            #endif
        }
        .alert("update_from_url".localized, isPresented: $showingURLAlert) {
            TextField("url_placeholder".localized, text: $updateURL)
            Button("cancel".localized, role: .cancel) { updateURL = "" }
            Button("done".localized) {
                if !updateURL.isEmpty {
                    viewModel.fetchHostsFromURL(url: updateURL, for: file) { success in
                        if success {
                            viewModel.updateSourceURL(for: file, url: updateURL)
                            if let updatedContent = viewModel.hostsFiles.first(where: { $0.id == file.id })?.content {
                                self.content = updatedContent
                            }
                        }
                    }
                    updateURL = ""
                }
            }
        } message: {
            Text("enter_url_update_guide".localized)
        }
        #if os(iOS) || os(macOS)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.plainText, .text, .data, .hosts, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let newContent = try? String(contentsOf: url) {
                            viewModel.updateContent(for: file, content: newContent)
                            self.content = newContent
                        }
                    }
                }
            case .failure(let error):
                print("Import failed: \(error)")
            }
        }
        #endif
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
