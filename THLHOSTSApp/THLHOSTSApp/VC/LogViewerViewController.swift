import UIKit
import SnapKit

class LogViewerViewController: UIViewController {
    
    private let textView: UITextView = {
        let tv = UITextView()
        #if os(iOS)
        tv.isEditable = false
        #endif
        tv.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.backgroundColor = .black
        tv.textColor = .green
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Logs"
        view.backgroundColor = .black
        
        setupUI()
        updateLogs()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLogs), name: HSBLogger.didUpdateLogs, object: nil)
        
        #if os(iOS)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLogs))
        #endif
        
        // Add Close/Clear buttons depending on presentation style
        if navigationController?.viewControllers.first == self {
             navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(dismissSelf))
        } else {
             #if os(iOS)
             navigationItem.rightBarButtonItems = [
                 UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLogs)),
                 UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLogs))
             ]
             #else
             navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLogs))
             #endif
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    @objc private func updateLogs() {
        let logs = HSBLogger.shared.logs.joined(separator: "\n")
        DispatchQueue.main.async {
            self.textView.text = logs
            if !logs.isEmpty {
                let bottom = NSMakeRange(logs.count - 1, 1)
                self.textView.scrollRangeToVisible(bottom)
            }
        }
    }
    
    @objc private func clearLogs() {
        HSBLogger.shared.clear()
    }
    
    @objc private func shareLogs() {
        #if os(iOS)
        let logs = HSBLogger.shared.logs.joined(separator: "\n")
        let activityVC = UIActivityViewController(activityItems: [logs], applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
             popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
        #endif
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
