import UIKit
import SnapKit

class LogViewerViewController: UIViewController {
    
    // [ZH] 背景特效
    private let glassBackground = HSBLiquidGlassView()

    private let textView: UITextView = {
        let tv = UITextView()
        #if os(iOS)
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 14, weight: .regular) // Increased to 14 for better readability
        #elseif os(tvOS)
        tv.isUserInteractionEnabled = true
        tv.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        tv.font = .monospacedSystemFont(ofSize: 30, weight: .regular)
        #endif
        // Transparent background for Glassmorphism
        tv.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.6)
        tv.textColor = .appCTA
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Logs"
        view.backgroundColor = .appBackground 
        
        setupUI()
        updateLogs()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLogs), name: HSBLogger.didUpdateLogs, object: nil)
        
        #if os(iOS)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLogs))
        #endif
        
        // Add Close/Clear buttons depending on presentation style
        // [ZH] 根据展示方式添加关闭/清除按钮
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
        // Add Glass Background
        view.addSubview(glassBackground)
        glassBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChange), name: .themeChanged, object: nil)
    }
    
    @objc private func handleThemeChange() {
        view.backgroundColor = .appBackground
        textView.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.6)
        textView.textColor = .appCTA
        glassBackground.backgroundColor = .appBackground
    }
    
    // [ZH] 更新日志显示
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
    
    // [ZH] 清除日志
    @objc private func clearLogs() {
        HSBLogger.shared.clear()
    }
    
    // [ZH] 分享日志
    @objc private func shareLogs() {
        #if os(iOS)
        let logs = HSBLogger.shared.logs.joined(separator: "\n")
        let activityVC = UIActivityViewController(activityItems: [logs], applicationActivities: nil)
        
        // iPad support
        // [ZH] iPad 支持
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
