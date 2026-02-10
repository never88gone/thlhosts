import UIKit
import SnapKit

class HostsDetailViewController: UIViewController {

    // Background Effects
    private let glassBackground = HSBLiquidGlassView()
    
    // MARK: - UI Elements
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
        // Semi-transparent background to blend with glass
        tv.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        tv.textColor = .white
        tv.isUserInteractionEnabled = true
        tv.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        #if !os(tvOS)
        tv.isEditable = false // Read-only for now
        #endif
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleLanguageChange), name: NSNotification.Name("HSBLanguageChanged"), object: nil)
        updateQRCode() // Initial load
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
    
    // MARK: - Public API
    func configure(with file: HostsFile) {
        titleLabel.text = file.name
        contentTextView.text = file.content
        let statusText = file.isEnabled ? HSBHostsLanguageManager.shared.localizedString("Status: Enabled") : HSBHostsLanguageManager.shared.localizedString("Status: Disabled")
        statusLabel.text = statusText
        statusLabel.textColor = file.isEnabled ? .systemGreen : .systemRed
    }
    
    func clear() {
        titleLabel.text = ""
        contentTextView.text = ""
        statusLabel.text = ""
    }
    
    func updateQRCode() {
        let ip = getWiFiAddress() ?? "localhost"
        let url = "http://\(ip):8080/upload"
        uploadInfoLabel.text = "\(HSBHostsLanguageManager.shared.localizedString("Scan to Upload:")) \(url)"
        qrImageView.image = generateQRCode(from: url)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Add Glass Background
        view.addSubview(glassBackground)
        glassBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(titleLabel)
        view.addSubview(statusLabel)
        view.addSubview(contentTextView)
        view.addSubview(uploadInfoLabel)
        view.addSubview(qrImageView)
    }
    
    private func setupLayout() {
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
    
    // MARK: - Utils
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
