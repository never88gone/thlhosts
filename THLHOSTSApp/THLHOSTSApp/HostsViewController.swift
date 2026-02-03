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
    
    // Left: List
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // setupLayout will be handled by updateViewConstraints or initial setup based on traits
        setupResponsiveLayout()
        
        // Load Data
        hostsFiles = HostsStorage.shared.load()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Long Press for Delete
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        tableView.addGestureRecognizer(longPress)
        
        startServer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: NSNotification.Name("HSBLanguageChanged"), object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // In case orientation changes affect traits/layout
        // But auto-layout constraints usually handle this if set up correctly.
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupResponsiveLayout()
        }
    }
    
    @objc private func handleLanguageChange() {
        tableView.reloadData()
        title = "Hosts"
        
        // Update Detail if Split
        if isSplitView(), let index = selectedIndex, index < hostsFiles.count {
            splitDetailVC.configure(with: hostsFiles[index])
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: point), indexPath.row > 0 {
                deleteHost(at: indexPath)
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(leftContainer)
        view.addSubview(rightContainer)
        
        leftContainer.addSubview(tableView)
        
        // Add Detail Child VC (for Split View scenarios)
        addChild(splitDetailVC)
        rightContainer.addSubview(splitDetailVC.view)
        splitDetailVC.view.snp.makeConstraints { make in
             make.edges.equalToSuperview()
        }
        splitDetailVC.didMove(toParent: self)
        
        // Settings Button
        let settingsButton = UIButton(type: .system)
        if #available(tvOS 13.0, *), #available(iOS 13.0, *) {
             settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)
        } else {
             settingsButton.setTitle("⚙️", for: .normal)
        }
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
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HostsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hostsFiles.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "+ \(HSBHostsLanguageManager.shared.localizedString("Add New Hosts"))"
            cell.textLabel?.textColor = .systemBlue
        } else {
            let file = hostsFiles[indexPath.row - 1]
            cell.textLabel?.text = file.name
            if file.isEnabled {
                cell.textLabel?.textColor = .systemGreen
            } else {
                cell.textLabel?.textColor = UIColor.darkGray
                 if #available(tvOS 13.0, *) {
                     cell.textLabel?.textColor = file.isEnabled ? .systemGreen : .secondaryLabel
                 }
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

// MARK: - Settings View Controller
class HostsSettingsViewController: UIViewController {

    // MARK: - Properties
    private let languages = [
        ("en", "English"),
        ("zh-Hans", "简体中文")
    ]
    
    // MARK: - UI Elements
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: NSNotification.Name("HSBLanguageChanged"), object: nil)
        updateTexts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleLanguageChange() {
        updateTexts()
        tableView.reloadData()
    }
    
    private func updateTexts() {
        title = HSBHostsLanguageManager.shared.localizedString("Language")
    }
    
    // MARK: - Setup
    private func setupUI() {
        #if os(iOS)
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        #endif
        
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
    }
    
    private func setupLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension HostsSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let (code, name) = languages[indexPath.row]
        
        cell.textLabel?.text = name
        
        // Checkmark for current language
        let current = HSBHostsLanguageManager.shared.currentLanguage
        if current == code {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let (code, _) = languages[indexPath.row]
        let current = HSBHostsLanguageManager.shared.currentLanguage
        
        if current != code {
            HSBHostsLanguageManager.shared.currentLanguage = code
            tableView.reloadData()
        }
    }
}
