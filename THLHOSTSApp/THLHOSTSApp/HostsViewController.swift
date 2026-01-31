
import UIKit
import SnapKit
import NetworkExtension

@objc class HostsViewController: UIViewController {
    
    @objc static func makeRootViewController() -> UIViewController {
        #if os(tvOS)
        return TVHostsViewController()
        #else
        return HostsViewController()
        #endif
    }
    
    // UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Hosts Tool", comment: "Title")
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("VPN Disconnected", comment: "Status")
        label.textColor = .systemRed
        return label
    }()
    
    private let toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Start", comment: "Button"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(statusLabel)
        view.addSubview(toggleButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalTo(view)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.centerX.equalTo(view)
        }
        
        toggleButton.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    private func setupActions() {
        toggleButton.addTarget(self, action: #selector(toggleVPN), for: .touchUpInside)
    }
    
    @objc private func toggleVPN() {
        if statusLabel.text == NSLocalizedString("VPN Connected", comment: "") {
            stopVPN()
        } else {
            startVPN()
        }
    }

    private func startVPN() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                print("Error loading preferences: \(error)")
                return
            }
            
            let manager = managers?.first ?? NETunnelProviderManager()
            
            manager.loadFromPreferences { error in
                if let error = error {
                    print("Error loading manager preferences: \(error)")
                    return
                }
                
                let protocolConfiguration = NETunnelProviderProtocol()
                protocolConfiguration.providerBundleIdentifier = Bundle.main.bundleIdentifier! + ".NetworkExtension" // Assumes generic naming convention
                protocolConfiguration.serverAddress = "127.0.0.1"
                
                manager.protocolConfiguration = protocolConfiguration
                manager.localizedDescription = "THLHOSTS - Hosts Tool"
                manager.isEnabled = true
                
                manager.saveToPreferences { error in
                    if let error = error {
                        print("Error saving preferences: \(error)")
                        return
                    }
                    
                    do {
                        try manager.connection.startVPNTunnel()
                        DispatchQueue.main.async {
                            self.updateStatus(connected: true)
                        }
                    } catch {
                        print("Error starting tunnel: \(error)")
                    }
                }
            }
        }
    }
    
    private func stopVPN() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            guard let manager = managers?.first else { return }
            manager.connection.stopVPNTunnel()
            DispatchQueue.main.async {
                self?.updateStatus(connected: false)
            }
        }
    }
    
    private func updateStatus(connected: Bool) {
        if connected {
            statusLabel.text = NSLocalizedString("VPN Connected", comment: "")
            statusLabel.textColor = .systemGreen
            toggleButton.setTitle(NSLocalizedString("Stop", comment: ""), for: .normal)
            toggleButton.backgroundColor = .systemRed
        } else {
            statusLabel.text = NSLocalizedString("VPN Disconnected", comment: "")
            statusLabel.textColor = .systemRed
            toggleButton.setTitle(NSLocalizedString("Start", comment: ""), for: .normal)
            toggleButton.backgroundColor = .systemBlue
        }
    }
}
