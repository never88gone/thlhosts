
import UIKit
import SnapKit
import Swifter
import NetworkExtension

class TVHostsViewController: UIViewController {

    // MARK: - Properties
    private var hostsFiles: [HostsFile] = []
    private var selectedIndex: Int?
    
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
    
    private let addParamsLabel: UILabel = {
        let label = UILabel()
        label.text = "Mock Add Params" // Placeholder
        label.isHidden = true
        return label
    }()
    
    // Right: Content
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let contentTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .regular)
        tv.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        tv.textColor = .white
        tv.isUserInteractionEnabled = true 
        tv.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        return tv
    }()
    
    private let uploadInfoLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Scan to Upload:", comment: "")
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    private let qrImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .white
        iv.layer.cornerRadius = 10
        iv.layer.masksToBounds = true
        return iv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        
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
        updateTexts()
    }
    
    @objc private func handleLanguageChange() {
        updateTexts()
        tableView.reloadData()
        
        // Refresh right panel if selected
        if let index = selectedIndex, index < hostsFiles.count {
            updateRightPanel(file: hostsFiles[index])
        }
    }
    
    private func updateTexts() {
        uploadInfoLabel.text = "\(HSBHostsLanguageManager.shared.localizedString("Scan to Upload:"))"
        // Force refresh QR label text part (IP might stay same)
        updateQRCode() 
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: point), indexPath.row > 1 { // Updated index check
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
        
        rightContainer.addSubview(titleLabel)
        rightContainer.addSubview(statusLabel)
        rightContainer.addSubview(contentTextView)
        rightContainer.addSubview(uploadInfoLabel)
        rightContainer.addSubview(qrImageView)
    }
    
    private func setupLayout() {
        leftContainer.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(500)
        }
        
        rightContainer.snp.makeConstraints { make in
            make.left.equalTo(leftContainer.snp.right)
            make.top.bottom.right.equalToSuperview()
        }
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        
        qrImageView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-60)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(200)
        }
        
        uploadInfoLabel.snp.makeConstraints { make in
            make.bottom.equalTo(qrImageView.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
        
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(40)
            make.bottom.equalTo(uploadInfoLabel.snp.top).offset(-30)
        }
    }
    
    // MARK: - Server
    private func startServer() {
        HostsManager.shared.onHostsUploaded = { [weak self] content in
            self?.handleUploadedContent(content)
        }
        HostsManager.shared.startServer(port: 8080)
        
        updateQRCode()
    }
    
    private func handleUploadedContent(_ content: String) {
        // Find "Uploaded" file or create one
        if let index = hostsFiles.firstIndex(where: { $0.name == "Uploaded" }) {
            hostsFiles[index].content = content
             if selectedIndex == index {
                updateRightPanel(file: hostsFiles[index])
            }
        } else {
            let newFile = HostsFile(name: "Uploaded", content: content, isEnabled: false)
            hostsFiles.append(newFile)
            HostsStorage.shared.save(hostsFiles)
            tableView.reloadData()
        }
    }
    
    private func updateQRCode() {
        let ip = getWiFiAddress() ?? "localhost"
        let url = "http://\(ip):8080/upload"
        uploadInfoLabel.text = "\(HSBHostsLanguageManager.shared.localizedString("Scan to Upload:")) \(url)"
        qrImageView.image = generateQRCode(from: url)
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
        let index = indexPath.row - 2 // Adjusted for extra row
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
                self.titleLabel.text = ""
                self.contentTextView.text = ""
                self.statusLabel.text = ""
                self.selectedIndex = nil
            }
        })
        present(alert, animated: true)
    }

    func updateRightPanel(file: HostsFile) {
        titleLabel.text = file.name
        contentTextView.text = file.content
        let statusText = file.isEnabled ? HSBHostsLanguageManager.shared.localizedString("Status: Enabled") : HSBHostsLanguageManager.shared.localizedString("Status: Disabled")
        statusLabel.text = statusText
        statusLabel.textColor = file.isEnabled ? .systemGreen : .systemRed
    }
    
    // Utils
    func getWiFiAddress() -> String? {
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
                    if name != "lo0" {
                         var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                         getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                         address = String(cString: hostname)
                         // Prefer en0 or en1 if available
                         if name == "en0" || name == "en1" {
                             break
                         }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }

    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension TVHostsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hostsFiles.count + 2 // +1 for "Add New", +1 for "Language"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "+ \(HSBHostsLanguageManager.shared.localizedString("Add New Hosts"))"
            cell.textLabel?.textColor = .systemBlue
        } else if indexPath.row == 1 {
            let currentLang = HSBHostsLanguageManager.shared.currentLanguage
            let langText = currentLang == "zh-Hans" ? "简体中文" : "English"
            cell.textLabel?.text = "\(HSBHostsLanguageManager.shared.localizedString("Language")): \(langText)"
            cell.textLabel?.textColor = .systemOrange
        } else {
            let file = hostsFiles[indexPath.row - 2]
            cell.textLabel?.text = file.name
            if file.isEnabled {
                cell.textLabel?.textColor = .systemGreen
            } else {
                cell.textLabel?.textColor = UIColor.darkGray // Better contrast for disabled state on dark bg
                // on tvOS focused cell text color is handled automatically, but for unfocused custom color:
                 if #available(tvOS 13.0, *) {
                     cell.textLabel?.textColor = file.isEnabled ? .systemGreen : .secondaryLabel
                 }
            }
        }
        return cell
    }

// ... focus update ...

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            addNewHost()
        } else if indexPath.row == 1 {
            // Toggle Language
            let current = HSBHostsLanguageManager.shared.currentLanguage
            HSBHostsLanguageManager.shared.currentLanguage = (current == "en" ? "zh-Hans" : "en")
            // Notification will trigger reload, but we can also force reload specific row if needed
            // Actually notification observer handles full reload.
        } else {
            // Toggle Logic
            let index = indexPath.row - 2
             if index < hostsFiles.count {
                hostsFiles[index].isEnabled.toggle()
                HostsStorage.shared.save(hostsFiles)
                updateRightPanel(file: hostsFiles[index])
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
}
