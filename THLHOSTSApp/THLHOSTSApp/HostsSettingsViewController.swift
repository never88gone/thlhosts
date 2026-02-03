import UIKit
import SnapKit

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
        if #available(iOS 13.0, tvOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
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
