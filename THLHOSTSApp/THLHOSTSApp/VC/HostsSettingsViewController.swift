import UIKit
import SnapKit

class HostsSettingsViewController: UIViewController {

    // MARK: - Properties
    // [ZH] 属性
    private let languages = [
        ("en", "English"),
        ("zh-Hans", "简体中文")
    ]
    
    private let sections = ["Language", "Tools"]
    
    // Background Effects
    private let glassBackground = HSBLiquidGlassView()
    
    // MARK: - UI Elements
    // [ZH] UI 元素
    private let tableView: UITableView = {
        let style: UITableView.Style
        #if os(iOS)
        style = .insetGrouped
        #else
        style = .grouped
        #endif
        
        let tv = UITableView(frame: .zero, style: style)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.backgroundColor = .clear // Transparent
        return tv
    }()
    
    // MARK: - Lifecycle
    // [ZH] 生命周期
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
        title = HSBHostsLanguageManager.shared.localizedString("Settings")
    }
    
    // MARK: - Setup
    // [ZH] 设置 UI
    private func setupUI() {
        view.backgroundColor = .clear
        
        // Add Glass Background
        view.addSubview(glassBackground)
        glassBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
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
// [ZH] TableView 数据源与代理
extension HostsSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return languages.count
        } else {
            return 1 // Logs
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return HSBHostsLanguageManager.shared.localizedString("Language")
        } else {
            return HSBHostsLanguageManager.shared.localizedString("Tools")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .clear
        
        // Fix Color for Focus/Theme
        // [ZH] 修正焦点/主题颜色
        cell.textLabel?.textColor = .white
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        cell.selectedBackgroundView = selectedBackgroundView
        
        if indexPath.section == 0 {
            let (code, name) = languages[indexPath.row]
            cell.textLabel?.text = name
            
            // Checkmark for current language
            // [ZH] 当前语言的勾选标记
            let current = HSBHostsLanguageManager.shared.currentLanguage
            if current == code {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            cell.textLabel?.text = HSBHostsLanguageManager.shared.localizedString("View Logs")
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            let (code, _) = languages[indexPath.row]
            let current = HSBHostsLanguageManager.shared.currentLanguage
            
            if current != code {
                HSBHostsLanguageManager.shared.currentLanguage = code
                tableView.reloadData()
            }
        } else {
            // Logs
            let logVC = LogViewerViewController()
            #if os(iOS)
            navigationController?.pushViewController(logVC, animated: true) ?? present(UINavigationController(rootViewController: logVC), animated: true)
            #else
            present(logVC, animated: true)
            #endif
        }
    }
}
