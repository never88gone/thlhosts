import SwiftUI

struct HostsListView: View {
    @ObservedObject var viewModel: HostsViewModel
    @Binding var showingSettings: Bool
    @Binding var showingPicker: Bool
    @State private var showingAddAlert = false
    @State private var showingImporter = false
    @State private var newFileName = ""
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                #if os(tvOS)
                tvOSHeader
                #endif
                
                contentArea
                
                #if os(tvOS)
                tvOSBottomActions
                #endif
            }
            #if os(tvOS)
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
            #endif
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Button(action: { showingImporter = true }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Button(action: { showingAddAlert = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.plainText, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importFile(from: url)
                }
            case .failure(let error):
                print("Import failed: \(error)")
            }
        }
        #endif
        .alert("new_hosts_file".localized, isPresented: $showingAddAlert) {
            TextField("name".localized, text: $newFileName)
            Button("cancel".localized, role: .cancel) { newFileName = "" }
            Button("add".localized) {
                if !newFileName.isEmpty {
                    viewModel.addNewHosts(name: newFileName)
                    newFileName = ""
                }
            }
        } message: {
            Text("enter_name_guide".localized)
        }
        #if os(tvOS)
        .navigationTitle("") // Hide system title on tvOS to avoid overlap with custom header
        #endif
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var contentArea: some View {
        if viewModel.hostsFiles.isEmpty {
            emptyPlaceholder
        } else {
            #if os(tvOS)
            tvOSActiveConfigCard
            #else
            mainList
            #endif
        }
    }
    
    private var mainList: some View {
        List {
            #if os(iOS)
            Section {
                Toggle("master_switch".localized, isOn: $viewModel.isVPNEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .appCTA))
            }
            #endif
            
            Section(header: Text("configurations".localized)) {
                ForEach(viewModel.hostsFiles) { file in
                    hostRow(file)
                }
            }
        }
        #if os(tvOS)
        .listStyle(PlainListStyle())
        #else
        .listStyle(InsetGroupedListStyle())
        #endif
    }
    
    #if os(tvOS)
    @FocusState private var isCardFocused: Bool
    
    private var tvOSActiveConfigCard: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Button(action: { showingPicker = true }) {
                VStack(spacing: 30) {
                    Text("active_config".localized)
                        .font(.headline)
                        .foregroundColor(isCardFocused ? .primary : .secondary)
                    
                    if let active = viewModel.activeHostsFile {
                        Text(active.name)
                            .font(.system(size: 90, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(isCardFocused ? .appCTA : .primary)
                    } else {
                        Text("no_configs".localized)
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.appMutedText)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                        Text("press_to_change".localized)
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .opacity(isCardFocused ? 1 : 0.6)
                }
                .padding(60)
                .frame(maxWidth: 800)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.white.opacity(isCardFocused ? 0.15 : 0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(isCardFocused ? Color.appCTA.opacity(0.5) : Color.clear, lineWidth: 4)
                        )
                )
            }
            .buttonStyle(.plain)
            .focused($isCardFocused)
            .scaleEffect(isCardFocused ? 1.05 : 1.0)
            .animation(.interactiveSpring(), value: isCardFocused)
            
            Spacer()
        }
    }
    #endif
    
    private var tvOSHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("app_name".localized)
                    .font(.system(size: 80, weight: .black))
                
                HStack(spacing: 20) {
                    Circle()
                        .fill(viewModel.isVPNEnabled ? Color.green : Color.gray)
                        .frame(width: 20, height: 20)
                    
                    Text("status".localized + ": " + (viewModel.isVPNEnabled ? "active".localized : "inactive".localized))
                        .font(.title2.bold())
                        .foregroundColor(viewModel.isVPNEnabled ? .appCTA : .secondary)
                }
            }
            
            Spacer()
            
            if let qrImage = generateQRCode(from: "http://\(viewModel.serverIP):8080") {
                VStack(spacing: 16) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 160, height: 160)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.4), radius: 15)
                    
                    VStack(spacing: 4) {
                        Text("scan_to_upload".localized)
                            .font(.headline)
                        Text("http://\(viewModel.serverIP):8080")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(24)
            }
        }
    }
    
    private var tvOSBottomActions: some View {
        HStack(spacing: 40) {
            Button(action: { viewModel.toggleVPN() }) {
                HStack {
                    Image(systemName: viewModel.isVPNEnabled ? "stop.fill" : "play.fill")
                    Text(viewModel.isVPNEnabled ? "stop_service".localized : "start_service".localized)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isVPNEnabled ? .red : .green)
            .disabled(viewModel.hostsFiles.isEmpty) // Disable if no configs
            
            Button(action: { showingAddAlert = true }) {
                Label("add".localized, systemImage: "plus")
                    .padding(.horizontal, 20)
            }
            
            Button(action: { showingSettings = true }) {
                Label("settings".localized, systemImage: "gearshape")
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private func hostRow(_ file: HostsFile) -> some View {
        Button(action: { 
            #if os(tvOS)
            viewModel.toggleHosts(file)
            #else
            viewModel.selectedFile = file 
            #endif
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(file.name)
                        .font(.title2.bold())
                        .foregroundColor(.appText)
                    Text(file.isEnabled ? "active".localized : "inactive".localized)
                        .font(.headline)
                        .foregroundColor(file.isEnabled ? .appCTA : .secondary)
                }
                Spacer()
                if file.isEnabled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.appCTA)
                }
            }
            .padding(30)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private var emptyPlaceholder: some View {
        VStack(spacing: 30) {
            Spacer()
            
            #if os(tvOS)
            Image(systemName: "tray.and.arrow.up")
                .font(.system(size: 120))
                .foregroundColor(.appCTA.opacity(0.6))
            
            VStack(spacing: 16) {
                Text("no_configs".localized)
                    .font(.system(size: 50, weight: .bold))
                Text("phone_upload_guide".localized)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 20)
            
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 10) {
                    GuideStep(number: 1, text: "step_1_wifi".localized)
                    GuideStep(number: 2, text: "step_2_scan".localized)
                    GuideStep(number: 3, text: "step_3_upload".localized)
                }
                .padding(40)
                .background(Color.white.opacity(0.05))
                .cornerRadius(24)
            }
            #else
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.appCTA.opacity(0.6))
            
            Text("no_configs".localized)
                .font(.title.bold())
                .foregroundColor(.appText)
            
            Text("click_plus_to_add".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
            #endif
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    struct GuideStep: View {
        let number: Int
        let text: String
        var body: some View {
            HStack(spacing: 15) {
                Text("\(number)")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.appCTA)
                    .clipShape(Circle())
                Text(text)
                    .font(.title3)
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

#Preview {
    NavigationView {
        HostsListView(viewModel: HostsViewModel(), showingSettings: .constant(false), showingPicker: .constant(false))
    }
}
