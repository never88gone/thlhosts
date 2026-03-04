import UIKit
import SnapKit

class HostsSettingsViewController: UIViewController {

    // MARK: - Properties
    // [ZH] 属性
    private let languages = [
        ("en", "English"),
        ("zh-Hans", "简体中文")
    ]
    
    private let sections = ["Language", "Theme", "Tools"]
    private let themes = AppTheme.allCases
    
    // Background Effects
    private let glassBackground = HSBLiquidGlassView()
    
    // MARK: - UI Elements
    // [ZH] UI 元素
    private let tableView: UITableView = {
        let style: UITableView.Style
        #if os(tvOS)
        style = .grouped
        #else
        style = .insetGrouped
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
        NotificationCenter.default.addObserver(self, selector: #selector(handleThemeChange), name: .themeChanged, object: nil)
        updateTexts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleLanguageChange() {
        updateTexts()
        tableView.reloadData()
    }
    
    @objc private func handleThemeChange() {
        view.backgroundColor = .appBackground
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return languages.count
        } else if section == 1 {
            return themes.count
        } else {
            return 1 // Logs
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return HSBHostsLanguageManager.shared.localizedString("Language")
        } else if section == 1 {
            return HSBHostsLanguageManager.shared.localizedString("Theme")
        } else {
            return HSBHostsLanguageManager.shared.localizedString("Tools")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        
        if indexPath.section == 0 {
            let (code, name) = languages[indexPath.row]
            content.text = name
            
            // Checkmark for current language
            let current = HSBHostsLanguageManager.shared.currentLanguage
            if current == code {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else if indexPath.section == 1 {
            let theme = themes[indexPath.row]
            content.text = theme.localizedName
            
            if ThemeManager.shared.currentTheme == theme {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            content.text = HSBHostsLanguageManager.shared.localizedString("View Logs")
            cell.accessoryType = .disclosureIndicator
        }
        
        // Font
        #if os(tvOS)
        content.textProperties.font = UIFont.systemFont(ofSize: 31, weight: .medium) // [ZH] tvOS 设置字体
        #endif
        
        cell.contentConfiguration = content
        
        // Configuration Update Handler for Contrast
        // [ZH] 自动对比度适配
        cell.configurationUpdateHandler = { cell, state in
            guard var content = cell.contentConfiguration as? UIListContentConfiguration else { return }
            
            if state.isFocused || state.isSelected {
                content.textProperties.color = .appBackground
            } else {
                content.textProperties.color = .appText
            }
            cell.contentConfiguration = content
            
            var background = UIBackgroundConfiguration.listGroupedCell()
            if state.isFocused || state.isSelected {
                background.backgroundColor = .appText
            } else {
                background.backgroundColor = .appPrimary
            }
            cell.backgroundConfiguration = background
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
        } else if indexPath.section == 1 {
            let selectedTheme = themes[indexPath.row]
            if ThemeManager.shared.currentTheme != selectedTheme {
                ThemeManager.shared.currentTheme = selectedTheme
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
