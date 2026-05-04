import Foundation
import SwiftUI
import Combine

class HostsViewModel: ObservableObject {
    @Published var hostsFiles: [HostsFile] = []
    @Published var selectedFile: HostsFile?
    @Published var isVPNEnabled: Bool = false
    @Published var serverIP: String = "localhost"
    @Published var showingImporterTrigger: Bool = false
    
    func triggerFileImport() {
        showingImporterTrigger = true
    }
    
    var activeHostsFile: HostsFile? {
        hostsFiles.first(where: { $0.isEnabled })
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        #if os(tvOS)
        self.serverIP = HSBHostsManager.shared.startServer() ?? "localhost"
        HSBLogger.shared.log("App 启动，HTTP 服务器地址: \(self.serverIP):8080", level: .info)
        #else
        HSBLogger.shared.log("App 启动 (iOS 模式)", level: .info)
        #endif
        
        loadData()
        HSBLogger.shared.log("已加载 \(self.hostsFiles.count) 个 Hosts 配置", level: .info)
        
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
        NotificationCenter.default.addObserver(forName: NSNotification.Name("HSBHostsUploaded"), object: nil, queue: .main) { [weak self] notification in
            if let filename = notification.object as? String {
                self?.syncUploadedFile(filename: filename)
            } else {
                self?.loadData()
            }
        }
    }
    
    private func syncUploadedFile(filename: String) {
        let fileURL = HSBHostsManager.shared.hostsDirectory.appendingPathComponent(filename)
        if let content = try? String(contentsOf: fileURL) {
            if let index = hostsFiles.firstIndex(where: { $0.name == filename }) {
                hostsFiles[index].content = content
            } else {
                let newFile = HostsFile(name: filename, content: content, isEnabled: false)
                hostsFiles.append(newFile)
            }
            HostsStorage.shared.save(hostsFiles)
            loadData()
            HSBLogger.shared.log("已同步远程上传的配置: \(filename)", level: .info)
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
                HSBLogger.shared.log("切换活跃配置 → \(file.name)", level: .info)
            } else {
                HSBHostsManager.shared.activeHost = nil
                HSBLogger.shared.log("停用配置: \(file.name)", level: .info)
            }
            
            updatedFiles[index].isEnabled = willEnable
            self.hostsFiles = updatedFiles
            HostsStorage.shared.save(updatedFiles)
            
            // Auto-enable VPN if a host is activated
            if willEnable && !isVPNEnabled {
                isVPNEnabled = true
                HSBHostsManager.shared.isVPNEnabled = true
                HSBLogger.shared.log("检测到配置激活，自动开启主开关", level: .info)
            }
        }
    }
    
    func deleteHosts(_ file: HostsFile) {
        HSBLogger.shared.log("删除配置: \(file.name)", level: .info)
        hostsFiles.removeAll(where: { $0.id == file.id })
        HostsStorage.shared.save(hostsFiles)
        HSBHostsManager.shared.deleteHostsFile(filename: file.name)
        
        if selectedFile?.id == file.id {
            selectedFile = nil
        }
    }
    
    func addNewHosts(name: String) {
        HSBLogger.shared.log("新建配置: \(name)", level: .info)
        let content = "# New Hosts File\n"
        let newFile = HostsFile(name: name, content: content, isEnabled: false)
        hostsFiles.append(newFile)
        HostsStorage.shared.save(hostsFiles)
        HSBHostsManager.shared.saveHostsContent(content, filename: name)
    }
    
    func addHostsFromURL(name: String, url: String) {
        HSBLogger.shared.log("从 URL 新建配置: \(name), URL: \(url)", level: .info)
        let newFile = HostsFile(name: name, content: url, isEnabled: false, sourceURL: url)
        hostsFiles.append(newFile)
        HostsStorage.shared.save(hostsFiles)
        HSBHostsManager.shared.saveHostsContent(url, filename: name)
        
        // Auto-fetch immediately
        fetchHostsFromURL(url: url, for: newFile) { _ in }
    }
    
    func updateContent(for file: HostsFile, content: String) {
        if let index = hostsFiles.firstIndex(where: { $0.id == file.id }) {
            hostsFiles[index].content = content
            HostsStorage.shared.save(hostsFiles)
            HSBHostsManager.shared.saveHostsContent(content, filename: file.name)
            
            // If it's active, we need to refresh the manager
            if hostsFiles[index].isEnabled {
                HSBHostsManager.shared.activeHost = hostsFiles[index].name
            }
        }
    }
    func updateSourceURL(for file: HostsFile, url: String) {
        if let index = hostsFiles.firstIndex(where: { $0.id == file.id }) {
            hostsFiles[index].sourceURL = url
            HostsStorage.shared.save(hostsFiles)
        }
    }
    
    func toggleVPN() {
        let activeFiles = hostsFiles.filter { $0.isEnabled }
        if activeFiles.isEmpty && !isVPNEnabled {
            HSBLogger.shared.log("[警告] 无法启动服务：未选择任何 Hosts 配置", level: .warning)
            return
        }
        
        isVPNEnabled.toggle()
        
        // If turning OFF, disable all hosts configurations
        if !isVPNEnabled {
            for i in 0..<hostsFiles.count {
                hostsFiles[i].isEnabled = false
            }
            HostsStorage.shared.save(hostsFiles)
            HSBHostsManager.shared.activeHost = nil
            HSBLogger.shared.log("主开关已关闭，已重置所有子配置状态", level: .info)
        }
        
        HSBHostsManager.shared.isVPNEnabled = isVPNEnabled
        HSBLogger.shared.log(isVPNEnabled ? "VPN 服务已启动" : "VPN 服务已停止", level: .info)
    }
    
    private func updateVPNStatus() {
        self.isVPNEnabled = HSBHostsManager.shared.isVPNEnabled
    }
    
    func fetchHostsFromURL(url: String, for file: HostsFile, completion: @escaping (Bool) -> Void) {
        guard let downloadURL = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            HSBLogger.shared.log("[错误] 无效的 URL: \(url)", level: .error)
            completion(false)
            return
        }
        
        HSBLogger.shared.log("正在从 URL 下载 Hosts: \(url)", level: .info)
        
        URLSession.shared.dataTask(with: downloadURL) { [weak self] data, response, error in
            if let error = error {
                HSBLogger.shared.log("[错误] 下载失败: \(error.localizedDescription)", level: .error)
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                HSBLogger.shared.log("[错误] 无法解析下载的数据", level: .error)
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            DispatchQueue.main.async {
                self?.updateContent(for: file, content: content)
                HSBLogger.shared.log("成功从网络更新配置: \(file.name)，长度: \(content.count)", level: .info)
                completion(true)
            }
        }.resume()
    }
    
    func importFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            HSBLogger.shared.log("[错误] 无法访问文件: \(url.lastPathComponent)", level: .error)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url)
            let filename = url.lastPathComponent
            
            // Save to disk
            let destinationURL = HSBHostsManager.shared.hostsDirectory.appendingPathComponent(filename)
            try content.write(to: destinationURL, atomically: true, encoding: .utf8)
            HSBLogger.shared.log("导入配置成功: \(filename)，共 \(content.components(separatedBy: "\n").count) 行", level: .info)
            
            // Sync with memory list and UserDefaults
            DispatchQueue.main.async {
                if let index = self.hostsFiles.firstIndex(where: { $0.name == filename }) {
                    // Update existing
                    self.hostsFiles[index].content = content
                    
                    // If this file is currently selected, update the selection reference
                    if self.selectedFile?.id == self.hostsFiles[index].id {
                        self.selectedFile = self.hostsFiles[index]
                    }
                } else {
                    // Add new
                    let newFile = HostsFile(name: filename, content: content, isEnabled: false)
                    self.hostsFiles.append(newFile)
                }
                HostsStorage.shared.save(self.hostsFiles)
                self.loadData()
                
                // Auto-select if nothing is selected
                if self.selectedFile == nil {
                    self.selectedFile = self.hostsFiles.last
                }
            }
        } catch {
            HSBLogger.shared.log("[错误] 导入文件失败: \(error.localizedDescription)", level: .error)
        }
    }
}
