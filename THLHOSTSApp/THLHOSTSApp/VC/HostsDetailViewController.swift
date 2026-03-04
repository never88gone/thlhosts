import UIKit
import SnapKit

class HostsDetailViewController: UIViewController {

    // Background Effects
    // [ZH] 背景特效
    private let glassBackground = HSBLiquidGlassView()
    
    // MARK: - UI Elements
    // [ZH] UI 元素
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        return sv
    }()
    
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        #if os(tvOS)
        label.font = UIFont.systemFont(ofSize: 54, weight: .bold) // [ZH] tvOS 大标题
        #else
        if DeviceHelper.isPadOrMac {
            label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        } else {
            label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        }
        #endif
        label.textAlignment = .center
        label.textColor = .appText
        label.numberOfLines = 0
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let contentTextView: UITextView = {
        let tv = UITextView()
        #if os(tvOS)
        tv.font = UIFont.monospacedSystemFont(ofSize: 31, weight: .regular) // [ZH] tvOS 正文 31pt+
        #else
        if DeviceHelper.isPadOrMac {
            tv.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .regular)
        } else {
            tv.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        }
        #endif
        // Semi-transparent background to blend with glass
        tv.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.6)
        tv.textColor = .appText
        tv.isUserInteractionEnabled = true
        tv.layer.cornerRadius = 10
        
        #if os(tvOS)
        tv.isSelectable = true
        tv.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        #else
        tv.isEditable = false
        #endif
        return tv
    }()
    
    private let uploadInfoLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Scan to Upload:", comment: "")
        label.textColor = .appMutedText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let qrImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .white
        iv.layer.cornerRadius = 10
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // MARK: - Lifecycle
    // [ZH] 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: NSNotification.Name("HSBLanguageChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChange), name: .themeChanged, object: nil)
        updateQRCode() // Initial load
        // [ZH] 初始加载
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleLanguageChange() {
        // Update static text if needed.
        // For upload label:
        updateQRCode()
        // Status label is updated via configure(with:) called by parent.
    }
    
    @objc private func handleThemeChange() {
        glassBackground.backgroundColor = .appBackground
        titleLabel.textColor = .appText
        contentTextView.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.6)
        contentTextView.textColor = .appText
        uploadInfoLabel.textColor = .appMutedText
        
        // Refresh status element if visible
        if let t = statusLabel.text {
            let isEnabled = t.contains(HSBHostsLanguageManager.shared.localizedString("Enabled")) || t.contains("Enabled")
            statusLabel.textColor = isEnabled ? .appCTA : .systemRed
        }
    }
    
    // MARK: - Public API
    // [ZH] 公共接口
    func configure(with file: HostsFile) {
        titleLabel.isHidden = false
        contentTextView.isHidden = false
        statusLabel.isHidden = false
        uploadInfoLabel.isHidden = false
        qrImageView.isHidden = false
        
        titleLabel.text = file.name
        contentTextView.text = file.content
        let statusText = file.isEnabled ? HSBHostsLanguageManager.shared.localizedString("Status: Enabled") : HSBHostsLanguageManager.shared.localizedString("Status: Disabled")
        statusLabel.text = statusText
        statusLabel.textColor = file.isEnabled ? .appCTA : .systemRed
    }
    
    func clear() {
        showEmptyState()
    }
    
    // Show empty state (for Add New)
    // [ZH] 显示空状态 (用于"添加新Hosts")
    func showEmptyState() {
        titleLabel.isHidden = true
        contentTextView.isHidden = true
        statusLabel.isHidden = true
        uploadInfoLabel.isHidden = true
        qrImageView.isHidden = true
    }
    
    func updateQRCode(name: String? = nil) {
        let ip = getWiFiAddress() ?? "localhost"
        var url = "http://\(ip):8080/"
        
        if let name = name, let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            url += "?name=\(encodedName)"
        }
        
        uploadInfoLabel.text = "\(HSBHostsLanguageManager.shared.localizedString("Scan to Upload:")) \(url)"
        qrImageView.image = generateQRCode(from: url)
        
        // Ensure visibility if configured
        // [ZH] 如果已配置，确保可见性
        if !titleLabel.isHidden {
            uploadInfoLabel.isHidden = false
            qrImageView.isHidden = false
        }
    }
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Add Glass Background
        view.addSubview(glassBackground)
        glassBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(contentTextView)
        contentView.addSubview(uploadInfoLabel)
        contentView.addSubview(qrImageView)
    }
    
    private func setupLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        let isTV = DeviceHelper.isTV
        let margin = isTV ? 60 : (DeviceHelper.isPadOrMac ? 40 : 20) // [ZH] tvOS 安全区域 60pt, iPad/Mac 40pt, 手机 20pt
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(margin)
            make.left.right.equalToSuperview().inset(margin)
            make.centerX.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(margin)
            make.centerX.equalToSuperview()
        }
        
        // Content Text View height
        // [ZH] 内容文本视图高度
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(margin)
            make.height.equalTo(300).priority(.medium) // Default height, scalable
            // [ZH] 默认高度，可缩放
            make.height.greaterThanOrEqualTo(200)
        }
        
        uploadInfoLabel.snp.makeConstraints { make in
            make.top.equalTo(contentTextView.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(margin)
            make.centerX.equalToSuperview()
        }
        
        qrImageView.snp.makeConstraints { make in
            make.top.equalTo(uploadInfoLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(isTV ? 300 : 200)
            make.bottom.equalToSuperview().offset(-margin)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceIdiom != traitCollection.userInterfaceIdiom {
            // Re-setup layout if idiom changes (rare but possible on iPad/Mac catalyst maybe)
            // Ideally just updating constraints or fonts would be better
            setupLayout()
        }
    }
    
    // MARK: - Utils
    // [ZH] 工具方法
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

    private func generateQRCode(from string: String) -> UIImage? {
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
