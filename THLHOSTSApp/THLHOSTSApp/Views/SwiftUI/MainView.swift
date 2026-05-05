import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = HostsViewModel()
    @State private var showingSettings = false
    @State private var showingPicker = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        Group {
            #if os(tvOS)
            stackView
            #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                splitView
            } else {
                stackView
            }
            #else
            splitView
            #endif
        }
        .background(Color.appBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        #if os(iOS) || os(macOS)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .preferredColorScheme(.dark)
        }
        #endif
        .alert("error".localized, isPresented: $viewModel.showingErrorAlert) {
            Button("ok".localized, role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Layouts
    
    private var splitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            HostsListView(viewModel: viewModel, showingSettings: $showingSettings, showingPicker: $showingPicker)
                #if os(tvOS)
                .navigationTitle("")
                #else
                .navigationTitle("app_name".localized)
                #endif
        } detail: {
            if let selected = viewModel.selectedFile {
                HostsDetailView(viewModel: viewModel, file: selected)
            } else if viewModel.hostsFiles.isEmpty {
                EmptyStateView(serverIP: viewModel.serverIP, onImport: {
                    viewModel.triggerFileImport()
                })
            } else {
                // List not empty but nothing selected
                VStack(spacing: 20) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 50))
                        .foregroundColor(.appCTA.opacity(0.5))
                    Text("请从左侧选择一个配置")
                        .font(.headline)
                        .foregroundColor(.appSubText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground.ignoresSafeArea())
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private var stackView: some View {
        NavigationStack {
            HostsListView(viewModel: viewModel, showingSettings: $showingSettings, showingPicker: $showingPicker)
                #if os(tvOS)
                .navigationTitle("")
                #else
                .navigationTitle("app_name".localized)
                #endif
                .navigationDestination(for: HostsFile.self) { file in
                    HostsDetailView(viewModel: viewModel, file: file)
                }
                .navigationDestination(isPresented: $showingSettings) {
                    SettingsView()
                }
                .navigationDestination(isPresented: $showingPicker) {
                    HostsPickerView(viewModel: viewModel)
                }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    MainView()
}

// MARK: - Picker View

struct HostsPickerView: View {
    @ObservedObject var viewModel: HostsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var focusedFileIdInPicker: UUID?
    @State private var showingURLAlert = false
    @State private var updateURL = ""
    @FocusState private var isContentFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: List of configurations
            VStack(alignment: .leading, spacing: 30) {
                Text("configurations".localized)
                    .font(.system(size: 60, weight: .bold))
                    .padding(.horizontal, 60)
                    .padding(.top, 60)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.hostsFiles) { file in
                            Button(action: {
                                viewModel.toggleHosts(file)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(file.name)
                                            .font(.title2.bold())
                                        if file.isEnabled {
                                            Text("active".localized)
                                                .font(.caption)
                                                .foregroundColor(.appCTA)
                                        }
                                    }
                                    Spacer()
                                    if file.isEnabled {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.appCTA)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    viewModel.deleteHosts(file)
                                }) {
                                    Label("delete".localized, systemImage: "trash")
                                }
                            }
                            .onFocusChange { focused in
                                if focused {
                                    focusedFileIdInPicker = file.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 60)
                }
            }
            .frame(width: 700)
            .background(Color.black.opacity(0.15))
            #if os(tvOS)
            .focusSection()
            #endif
            
            // Right: Content Preview
            VStack(alignment: .leading, spacing: 30) {
                let fileToDisplay = viewModel.hostsFiles.first(where: { $0.id == focusedFileIdInPicker }) ?? viewModel.activeHostsFile ?? viewModel.hostsFiles.first
                
                if let file = fileToDisplay {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(file.name)
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.appCTA)
                        
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("hosts_content".localized)
                        }
                        .font(.title3)
                        .foregroundColor(.secondary)
                    }
                    
                    ScrollView {
                        // 性能优化：巨大文件仅渲染前 2000 个字符用于预览
                        let isOversize = file.content.count > 2000
                        let displayContent = isOversize ? String(file.content.prefix(2000)) + "\n\n... (" + "content_too_long_preview_only".localized + ") ..." : file.content
                        
                        Text(displayContent)
                            .font(.system(.title3, design: .monospaced))
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(40)
                    }
                    #if os(tvOS)
                    .focusable(true)
                    .focused($isContentFocused)
                    #endif
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(isContentFocused ? 0.15 : 0.05))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isContentFocused ? Color.white : Color.white.opacity(0.1), lineWidth: 3)
                    )
                    
                    // Bottom actions and QR code
                    HStack(alignment: .center, spacing: 40) {
                        Button(action: {
                            let defaultURL = "https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/full/hosts.txt"
                            updateURL = (file.sourceURL?.isEmpty == false) ? file.sourceURL! : defaultURL
                            showingURLAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                Text("update_from_url".localized)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        #if os(tvOS)
                        .buttonStyle(.borderedProminent)
                        #else
                        .buttonStyle(.bordered)
                        #endif
                        
                        Spacer()
                        
                        if let encodedName = file.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let qrImage = generateQRCode(from: "http://\(viewModel.serverIP):8080/?target=\(encodedName)") {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("scan_to_upload".localized)
                                        .font(.headline)
                                        .foregroundColor(.appText)
                                    Text("http://\(viewModel.serverIP):8080")
                                        .font(.caption)
                                        .foregroundColor(.appSubText)
                                }
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .frame(width: 150, height: 150)
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                        }
                    }
                    #if os(tvOS)
                    .focusSection()
                    #endif
                } else {
                    Spacer()
                    VStack(spacing: 30) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 120))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("no_configs".localized)
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            .padding(80)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground)
            #if os(tvOS)
            .focusSection()
            #endif
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            focusedFileIdInPicker = viewModel.activeHostsFile?.id ?? viewModel.hostsFiles.first?.id
        }
        .overlay {
            if showingURLAlert {
                ZStack {
                    Color.black.opacity(0.8).ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Text("update_from_url".localized)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("enter_url_update_guide".localized)
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        TextField("url_placeholder".localized, text: $updateURL)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        HStack(spacing: 40) {
                            Button(action: {
                                showingURLAlert = false
                                updateURL = ""
                            }) {
                                Text("cancel".localized)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                            }
                            #if os(tvOS)
                            .buttonStyle(.bordered)
                            #endif
                            
                            Button(action: {
                                if !updateURL.isEmpty {
                                    let file = viewModel.hostsFiles.first(where: { $0.id == focusedFileIdInPicker }) ?? viewModel.activeHostsFile ?? viewModel.hostsFiles.first
                                    if let file = file {
                                        viewModel.fetchHostsFromURL(url: updateURL, for: file) { success in
                                            if success {
                                                viewModel.updateSourceURL(for: file, url: updateURL)
                                            }
                                        }
                                    }
                                    showingURLAlert = false
                                    updateURL = ""
                                }
                            }) {
                                Text("done".localized)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                            }
                            #if os(tvOS)
                            .buttonStyle(.borderedProminent)
                            #endif
                        }
                        .padding(.top, 20)
                    }
                    .padding(60)
                    .frame(maxWidth: 800)
                    .background(Color(white: 0.15))
                    .cornerRadius(30)
                    .shadow(radius: 20)
                }
                .zIndex(1000)
            } else if viewModel.isDownloading {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(2)
                        Text("downloading".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                }
                .zIndex(999)
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter(name: "CIQRCodeGenerator")
        let data = string.data(using: .ascii)
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("M", forKey: "inputCorrectionLevel")

        if let outputImage = filter?.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

// MARK: - View Extensions

extension View {
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> some View {
        self.modifier(FocusModifier(action: action))
    }
}

struct FocusModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    let action: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { newValue in
                action(newValue)
            }
    }
}
