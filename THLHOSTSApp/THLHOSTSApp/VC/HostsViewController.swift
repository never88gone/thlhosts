import UIKit
import SnapKit
import Swifter
import NetworkExtension

class HostsViewController: UIViewController {

    // MARK: - Properties
    private var hostsFiles: [HostsFile] = []
    private var selectedIndex: Int?
    
    // Detail VC for Split Layout (iPad/TV)
    private let splitDetailVC = HostsDetailViewController()
    
    // MARK: - UI Elements
    private let leftContainer = UIView()
    private let rightContainer = UIView()
    
    // Background Effects
    private let glassBackground = HSBLiquidGlassView()
    
    // Left: List
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.backgroundColor = .clear // Transparent for glass effect
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        // Clear background to show whatever is behind or default
        view.backgroundColor = .clear
        
        // Add Glass Background
        view.addSubview(glassBackground)
        glassBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(leftContainer)
        view.addSubview(rightContainer)
        
        leftContainer.addSubview(tableView)
        
        // ... (Child VC setup remains)
        
        // Settings Button
        let settingsButton = UIButton(type: .system)
        if #available(tvOS 13.0, *), #available(iOS 13.0, *) {
             settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        } else {
             settingsButton.setTitle("⚙️", for: .normal)
        }
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
    }
    
    private func isSplitView() -> Bool {
        #if os(tvOS)
        return true
        #else
        return traitCollection.horizontalSizeClass == .regular
        #endif
    }
    
    // MARK: - Server
    private func startServer() {
        HostsManager.shared.onHostsUploaded = { [weak self] content in
            self?.handleUploadedContent(content)
        }
        HostsManager.shared.startServer(port: 8080)
        
        // Initial Detail Update
        splitDetailVC.updateQRCode()
    }
    
    private func handleUploadedContent(_ content: String) {
        if let index = hostsFiles.firstIndex(where: { $0.name == "Uploaded" }) {
            hostsFiles[index].content = content
        } else {
            let newFile = HostsFile(name: "Uploaded", content: content, isEnabled: false)
            hostsFiles.append(newFile)
            HostsStorage.shared.save(hostsFiles)
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.isSplitView(), let index = self.hostsFiles.firstIndex(where: { $0.name == "Uploaded" }) {
                self.splitDetailVC.configure(with: self.hostsFiles[index])
            }
        }
    }

    // MARK: - Logic
    func addNewHost() {
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
    
    // ...

    // MARK: - UITableViewDataSource, UITableViewDelegate
    // ... 
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .clear // Transparent cell
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "+ \(HSBHostsLanguageManager.shared.localizedString("Add New Hosts"))"
            // Use system colors that adapt to focus
             if #available(tvOS 13.0, *), #available(iOS 13.0, *) {
                 cell.textLabel?.textColor = .systemBlue
             } else {
                 cell.textLabel?.textColor = .blue
             }
        } else {
            let file = hostsFiles[indexPath.row - 1]
            cell.textLabel?.text = file.name
            
            // Fix "White on White": Use standard label colors which handle focus automatically on tvOS
             if #available(tvOS 13.0, *), #available(iOS 13.0, *) {
                 cell.textLabel?.textColor = file.isEnabled ? .systemGreen : .label
             } else {
                 cell.textLabel?.textColor = file.isEnabled ? .green : .darkGray
             }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            addNewHost()
        } else {
            let index = indexPath.row - 1
            if index < hostsFiles.count {
                let file = hostsFiles[index]
                
                if isSplitView() {
                    // Split Logic: View + Toggle (Legacy)
                    selectedIndex = index
                    splitDetailVC.configure(with: file)
                    
                    hostsFiles[index].isEnabled.toggle()
                    HostsStorage.shared.save(hostsFiles)
                    splitDetailVC.configure(with: hostsFiles[index])
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                } else {
                    // Stack Logic: Nav to Detail
                    let detail = HostsDetailViewController()
                    detail.configure(with: file)
                    navigationController?.pushViewController(detail, animated: true)
                }
            }
        }
    }
}

