
import UIKit
import SnapKit
import NetworkExtension

class TVHostsViewController: UIViewController {
    
    // UI Elements Optimized for TV
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Hosts Tool", comment: "Title")
        label.font = UIFont.systemFont(ofSize: 50, weight: .bold) // Larger font
        label.textAlignment = .center
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("VPN Disconnected", comment: "Status")
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        return label
    }()
    
    private let toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("Start", comment: "Button"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 20
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .black // TV standard usually dark
        
        view.addSubview(titleLabel)
        view.addSubview(statusLabel)
        view.addSubview(toggleButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(100)
            make.centerX.equalTo(view)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(50)
            make.centerX.equalTo(view)
        }
        
        toggleButton.snp.makeConstraints { make in
            make.center.equalTo(view)
            make.width.equalTo(400)
            make.height.equalTo(120)
        }
    }
    
    private func setupActions() {
        toggleButton.addTarget(self, action: #selector(toggleVPN), for: .primaryActionTriggered) // TV uses primaryActionTriggered
    }
    
    // Focus Engine
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [toggleButton]
    }
    
    @objc private func toggleVPN() {
        // Shared logic with HostsViewController, ideally extracted to a ViewModel
        // For now, simpler implementation for proof of concept
         if statusLabel.text == NSLocalizedString("VPN Connected", comment: "") {
            // Logic to stop
             updateStatus(connected: false)
        } else {
            // Logic to start
             updateStatus(connected: true)
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
