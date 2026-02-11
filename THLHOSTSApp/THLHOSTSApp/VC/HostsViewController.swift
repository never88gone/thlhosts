import UIKit
import SnapKit
import Swifter
import NetworkExtension
import UniformTypeIdentifiers

class HostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    private var hostsFiles: [HostsFile] = []
    private var selectedIndex: Int?
    
    // Detail VC for Split Layout (iPad/TV)
    // [ZH] 分屏布局详情控制器 (iPad/TV)
    private let splitDetailVC = HostsDetailViewController()
    
    // MARK: - UI Elements
    // [ZH] UI 元素
    private let leftContainer = UIView()
    private let rightContainer = UIView()
    
    // Background Effects
    private let glassBackground = HSBLiquidGlassView()
    
    // Left: List
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(HostsListCell.self, forCellReuseIdentifier: "cell")
        tv.backgroundColor = .clear // Transparent for glass effect
        return tv
    }()
    
    // MARK: - Lifecycle
    // [ZH] 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupResponsiveLayout()
        
        // Load Data
        // [ZH] 加载数据
        hostsFiles = HostsStorage.shared.load()
        tableView.reloadData()
        
        // Start Server
        // [ZH] 启动服务器
        startServer()
    }

    // MARK: - Setup
    // [ZH] 设置 UI
    private func setupUI() {
        // Clear background to show whatever is behind or default
        // [ZH] 清除背景以显示背后的内容或默认背景
        view.backgroundColor = .clear
        
        // Add Glass Background
        view.addSubview(glassBackground)
        glassBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(leftContainer)
        view.addSubview(rightContainer)
        
        leftContainer.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Add Detail Child VC
        addChild(splitDetailVC)
        rightContainer.addSubview(splitDetailVC.view)
        splitDetailVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        splitDetailVC.didMove(toParent: self)
        
        // Settings Button
        let settingsButton = UIButton(type: .system)
        // Use larger config
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: config), for: .normal)
        // Use system tint color (which adapts to focus) or a specific color that works on glass
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .primaryActionTriggered)
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
        
        view.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-20)
            make.width.height.equalTo(60)
        }
    }
    
    @objc private func didTapSettings() {
        let settingsVC = HostsSettingsViewController()
        present(settingsVC, animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupResponsiveLayout()
        }
    }
    
    private func setupResponsiveLayout() {
        // Use remakConstraints to update layout based on current state
        if isSplitView() {
            // Split Layout
            leftContainer.snp.remakeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.width.equalTo(500).priority(.high)
                make.width.equalToSuperview().multipliedBy(0.4).priority(.medium)
            }
            
            // Ensure right container is visible and layout correct
            rightContainer.isHidden = false
            rightContainer.snp.remakeConstraints { make in
                make.left.equalTo(leftContainer.snp.right)
                make.top.bottom.right.equalToSuperview()
            }
            
            tableView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            // Stack Layout
            leftContainer.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            rightContainer.isHidden = true
            
            tableView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        // Refresh detail view if needed
        if isSplitView() {
             if let selectedIndex = selectedIndex, selectedIndex < hostsFiles.count {
                 splitDetailVC.configure(with: hostsFiles[selectedIndex])
             } else {
                 if let index = hostsFiles.firstIndex(where: { $0.name == "Uploaded" }) {
                     splitDetailVC.configure(with: hostsFiles[index])
                 } else {
                     splitDetailVC.clear()
                 }
             }
        }
    }
    
    private func isSplitView() -> Bool {
        #if os(tvOS)
        // [ZH] tvOS 始终使用分屏
        return true
        #else
        // [ZH] iPad 横屏或其他宽屏设备使用分屏
        return traitCollection.horizontalSizeClass == .regular
        #endif
    }
    
    // MARK: - Server
    // [ZH] 服务器相关
    private func startServer() {
        HostsManager.shared.onHostsUploaded = { [weak self] name, content in
            self?.handleUploadedContent(name: name, content: content)
        }
        HostsManager.shared.startServer(port: 8080)
        
        // Initial Detail Update
        // [ZH] 初始详情更新
        splitDetailVC.updateQRCode()
    }
    
    private func handleUploadedContent(name: String, content: String) {
        if let index = hostsFiles.firstIndex(where: { $0.name == name }) {
            hostsFiles[index].content = content
        } else {
            let newFile = HostsFile(name: name, content: content, isEnabled: false)
            hostsFiles.append(newFile)
            HostsStorage.shared.save(hostsFiles)
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.isSplitView(), let index = self.hostsFiles.firstIndex(where: { $0.name == name }) {
                self.splitDetailVC.configure(with: self.hostsFiles[index])
            }
        }
    }

    // MARK: - Logic
    // [ZH] 业务逻辑
    func addNewHost() {
        #if os(iOS)
        // iOS: Select local file or Create New
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: HSBHostsLanguageManager.shared.localizedString("Import from File"), style: .default) { [weak self] _ in
            self?.openDocumentPicker()
        })
        alert.addAction(UIAlertAction(title: HSBHostsLanguageManager.shared.localizedString("Create New"), style: .default) { [weak self] _ in
            self?.showCreateNameAlert()
        })
        alert.addAction(UIAlertAction(title: HSBHostsLanguageManager.shared.localizedString("Cancel"), style: .cancel))
        
        // iPad Popover support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
        #else
        // tvOS: Manual Create (Scan code is passive)
        showCreateNameAlert()
        #endif
    }
    
    private func showCreateNameAlert() {
        let alert = UIAlertController(title: HSBHostsLanguageManager.shared.localizedString("New Hosts File"), message: HSBHostsLanguageManager.shared.localizedString("Enter name"), preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = HSBHostsLanguageManager.shared.localizedString("Name")
        }
        alert.addAction(UIAlertAction(title: HSBHostsLanguageManager.shared.localizedString("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: HSBHostsLanguageManager.shared.localizedString("Add"), style: .default) { [weak self] _ in
            guard let self = self, let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let newFile = HostsFile(name: name, content: "# New Hosts File\n", isEnabled: false)
            self.hostsFiles.append(newFile)
            HostsStorage.shared.save(self.hostsFiles)
            self.tableView.reloadData()
        })
        present(alert, animated: true)
    }
    
    #if os(iOS)
    private func openDocumentPicker() {
        let types: [UTType] = [.text, .data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    #endif
    
    func deleteHost(at indexPath: IndexPath) {
        let index = indexPath.row - 1
        guard index >= 0 && index < hostsFiles.count else { return }
        
        let file = hostsFiles[index]
        let alert = UIAlertController(title: "\(HSBHostsLanguageManager.shared.localizedString("Delete")) \(file.name)?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: HSBHostsLanguageManager.shared.localizedString("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: HSBHostsLanguageManager.shared.localizedString("Delete"), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.hostsFiles.remove(at: index)
            HostsStorage.shared.save(self.hostsFiles)
            self.tableView.reloadData()
            
            if self.selectedIndex == index {
                self.splitDetailVC.clear()
                self.selectedIndex = nil
            }
        })
        present(alert, animated: true)
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hostsFiles.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! HostsListCell
        
        if indexPath.row == 0 {
            cell.configure(text: "+ \(HSBHostsLanguageManager.shared.localizedString("Add New Hosts"))", isAddButton: true)
        } else {
            let file = hostsFiles[indexPath.row - 1]
            cell.configure(text: file.name, isEnabled: file.isEnabled)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        #if os(tvOS)
        return 100
        #else
        return 60
        #endif
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row > 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteHost(at: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if isSplitView() {
                // Clear detail view when "Add New" is selected
                splitDetailVC.showEmptyState()
            }
            addNewHost()
        } else {
            let index = indexPath.row - 1
            if index < hostsFiles.count {
                let file = hostsFiles[index]
                
                if isSplitView() {
                    // Split Logic: View + Toggle (Legacy)
                    selectedIndex = index
                    splitDetailVC.configure(with: file)
                    // Update QR Code with file name
                    splitDetailVC.updateQRCode(name: file.name)
                    
                    hostsFiles[index].isEnabled.toggle()
                    HostsStorage.shared.save(hostsFiles)
                    // Re-configure to update status
                    splitDetailVC.configure(with: hostsFiles[index])
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                } else {
                    // Stack Logic: Nav to Detail
                    let detail = HostsDetailViewController()
                    detail.configure(with: file)
                    detail.updateQRCode(name: file.name)
                    navigationController?.pushViewController(detail, animated: true)
                }
            }
        }
    }
    
    // MARK: - Focus (tvOS)
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        guard let nextView = context.nextFocusedView,
              let cell = nextView as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }
        
        if indexPath.row == 0 {
             if isSplitView() { splitDetailVC.showEmptyState() }
        } else {
            let index = indexPath.row - 1
            if index < hostsFiles.count {
                let file = hostsFiles[index]
                if isSplitView() {
                     splitDetailVC.configure(with: file)
                     splitDetailVC.updateQRCode(name: file.name)
                }
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate (iOS Only)
#if os(iOS)
extension HostsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Access security scoped resource
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let filename = url.lastPathComponent
            
            // Add to hosts files
            // Check if exists
            let name = filename
            if let index = hostsFiles.firstIndex(where: { $0.name == name }) {
                // Update
                hostsFiles[index].content = content
            } else {
                // Create
                let newFile = HostsFile(name: name, content: content, isEnabled: false)
                hostsFiles.append(newFile)
            }
            HostsStorage.shared.save(hostsFiles)
            tableView.reloadData()
            
            // Show confirmation
            let alert = UIAlertController(title: HSBHostsLanguageManager.shared.localizedString("Success"), message: "\(name) imported.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            
        } catch {
            HSBLogger.shared.log("Import failed: \(error)", level: .error)
            let alert = UIAlertController(title: "Error", message: "Failed to read file: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
#endif
