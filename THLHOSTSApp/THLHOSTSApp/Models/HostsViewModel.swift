import Foundation
import SwiftUI
import Combine

class HostsViewModel: ObservableObject {
    @Published var hostsFiles: [HostsFile] = []
    @Published var selectedFile: HostsFile?
    @Published var isVPNEnabled: Bool = false
    @Published var serverIP: String = "localhost"
    
    var activeHostsFile: HostsFile? {
        hostsFiles.first(where: { $0.isEnabled })
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.serverIP = HSBHostsManager.shared.startServer() ?? "localhost"
        loadData()
        
        // Subscribe to VPN status changes
        NotificationCenter.default.publisher(for: .NEVPNStatusDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateVPNStatus()
            }
            .store(in: &cancellables)
            
        // Subscribe to Language changes
        NotificationCenter.default.publisher(for: NSNotification.Name("HSBLanguageChanged"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.loadData()
            }
            .store(in: &cancellables)
            
        setupObservers()
        updateVPNStatus()
    }
    
    func loadData() {
        self.hostsFiles = HostsStorage.shared.load()
        updateVPNStatus()
    }
    
    private func setupObservers() {
        // Observe VPN status from HSBHostsManager
        HSBHostsManager.shared.$isVPNEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: \.isVPNEnabled, on: self)
            .store(in: &cancellables)
        
        // Listen for remote uploads
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HSBHostsUploaded"), object: nil, queue: .main) { [weak self] _ in
            self?.loadData()
        }
    }
    
    func toggleHosts(_ file: HostsFile) {
        var updatedFiles = hostsFiles
        if let index = updatedFiles.firstIndex(where: { $0.id == file.id }) {
            let willEnable = !updatedFiles[index].isEnabled
            
            // If enabling, disable all others
            if willEnable {
                for i in 0..<updatedFiles.count {
                    updatedFiles[i].isEnabled = false
                }
                HSBHostsManager.shared.activeHost = file.name
            } else {
                HSBHostsManager.shared.activeHost = nil
            }
            
            updatedFiles[index].isEnabled = willEnable
            self.hostsFiles = updatedFiles
            HostsStorage.shared.save(updatedFiles)
        }
    }
    
    func deleteHosts(_ file: HostsFile) {
        hostsFiles.removeAll(where: { $0.id == file.id })
        HostsStorage.shared.save(hostsFiles)
        HSBHostsManager.shared.deleteHostsFile(filename: file.name)
        
        if selectedFile?.id == file.id {
            selectedFile = nil
        }
    }
    
    func addNewHosts(name: String) {
        let newFile = HostsFile(name: name, content: "# New Hosts File\n", isEnabled: false)
        hostsFiles.append(newFile)
        HostsStorage.shared.save(hostsFiles)
    }
    
    func updateContent(for file: HostsFile, content: String) {
        if let index = hostsFiles.firstIndex(where: { $0.id == file.id }) {
            hostsFiles[index].content = content
            HostsStorage.shared.save(hostsFiles)
            
            // If it's active, we need to refresh the manager
            if hostsFiles[index].isEnabled {
                HSBHostsManager.shared.activeHost = hostsFiles[index].name
            }
        }
    }
    
    func toggleVPN() {
        let activeFiles = hostsFiles.filter { $0.isEnabled }
        if activeFiles.isEmpty {
            HSBLogger.shared.log("Cannot start service: No hosts configuration selected.", level: .warning)
            // Optionally set a flag to show an alert in UI
            return
        }
        
        isVPNEnabled.toggle()
        HSBHostsManager.shared.isVPNEnabled = isVPNEnabled
    }
    
    private func updateVPNStatus() {
        self.isVPNEnabled = HSBHostsManager.shared.isVPNEnabled
    }
    
    func importFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url)
            let filename = url.lastPathComponent
            
            // Save to disk
            let destinationURL = HSBHostsManager.shared.hostsDirectory.appendingPathComponent(filename)
            try content.write(to: destinationURL, atomically: true, encoding: .utf8)
            
            loadData()
        } catch {
            print("Failed to import file: \(error)")
        }
    }
}
