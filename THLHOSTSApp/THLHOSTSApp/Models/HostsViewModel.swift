import Foundation
import SwiftUI
import Combine

class HostsViewModel: ObservableObject {
    @Published var hostsFiles: [HostsFile] = []
    @Published var selectedFile: HostsFile?
    @Published var isVPNEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadData()
        setupObservers()
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
    
    private func updateVPNStatus() {
        self.isVPNEnabled = HSBHostsManager.shared.isVPNEnabled
    }
}
