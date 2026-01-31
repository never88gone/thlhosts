
import UIKit
import CoreImage.CIFilterBuiltins
import SnapKit

@objc public class HSBHostsViewController: UIViewController {
    
    private var splitVC: UISplitViewController!
    private var listVC: HSBHostsListViewController!
    private var contentVC: HSBHostsContentViewController!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyLiquidGlassEffect()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.12, green: 0.14, blue: 0.22, alpha: 1.0)
        
        listVC = HSBHostsListViewController()
        contentVC = HSBHostsContentViewController()
        
        // Setup List VC Selection Handler
        listVC.onSelectHost = { [weak self] filename in
            self?.contentVC.loadContent(filename: filename)
        }
        
        listVC.onAddHost = { [weak self] in
            self?.showUploadQR()
        }
        
        splitVC = UISplitViewController()
        splitVC.viewControllers = [listVC, contentVC]
        splitVC.preferredDisplayMode = .oneBesideSecondary
        splitVC.maximumPrimaryColumnWidth = 600
        
        addChild(splitVC)
        view.addSubview(splitVC.view)
        splitVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        splitVC.didMove(toParent: self)
    }
    
    private func applyLiquidGlassEffect() {
        #if os(tvOS)
        if #available(tvOS 17.0, *) {
            if let liquidGlassManager = NSClassFromString("HSBLiquidGlassManager") as? NSObject.Type,
               let shared = liquidGlassManager.perform(NSSelectorFromString("shared"))?.takeUnretainedValue() as? NSObject {
                _ = shared.perform(NSSelectorFromString("addLiquidEffect:"), with: view)
            }
        }
        #endif
    }
    
    private func showUploadQR() {
        let uploadVC = HSBHostsUploadQRCodeVC()
        uploadVC.onDismiss = { [weak self] in
            self?.listVC.loadData()
        }
        uploadVC.modalPresentationStyle = .overFullScreen
        
        // Add fade-in animation
        uploadVC.modalTransitionStyle = .crossDissolve
        present(uploadVC, animated: true, completion: nil)
    }
}

// MARK: - List View Controller
class HSBHostsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var onSelectHost: ((String) -> Void)?
    var onAddHost: (() -> Void)?
    
    private var tableView: UITableView!
    private var addBtn: UIButton!
    private var statusLabel: UILabel!
    private var loadingIndicator: UIActivityIndicatorView!
    private var errorView: UIView?
    private var files: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDataWithRetry()
        
        // Observe upload success and active host changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hostsDidUpdate),
            name: NSNotification.Name("HSBHostsDidUpdate"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func hostsDidUpdate() {
        loadDataWithRetry()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.12, blue: 0.2, alpha: 0.95)
        
        // Loading indicator
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        
        // Status Label (showing current active hosts)
        statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 22, weight: .medium)
        statusLabel.textColor = .systemGreen
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        view.addSubview(statusLabel)
        
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HSBHostsCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .clear
        tableView.remembersLastFocusedIndexPath = true
        tableView.separatorStyle = .none
        view.addSubview(tableView)
        
        addBtn = UIButton(type: .system)
        addBtn.setTitle("Add Hosts File".smb_localized, for: .normal)
        addBtn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addBtn.titleLabel?.font = .systemFont(ofSize: 24, weight: .semibold)
        addBtn.tintColor = .systemBlue
        addBtn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        addBtn.layer.cornerRadius = 12
        addBtn.addTarget(self, action: #selector(didClickAdd), for: .primaryActionTriggered)
        view.addSubview(addBtn)
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(addBtn.snp.top).offset(-20)
        }
        
        addBtn.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-40)
            make.centerX.equalToSuperview()
            make.height.equalTo(60)
            make.width.equalTo(300)
        }
    }
    
    private func loadDataWithRetry(retryCount: Int = 0) {
        loadingIndicator.startAnimating()
        errorView?.removeFromSuperview()
        errorView = nil
        
        // Simulate async loading with error handling
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var loadedFiles: [String] = []
            var loadError: Error?
            
            do {
                loadedFiles = HSBHostsManager.shared.listHostsFiles()
            } catch {
                loadError = error
            }
            
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                if let error = loadError {
                    if retryCount < 3 {
                        // Auto retry
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self?.loadDataWithRetry(retryCount: retryCount + 1)
                        }
                    } else {
                        self?.showError(error)
                    }
                } else {
                    self?.files = loadedFiles
                    self?.tableView.reloadData()
                    self?.updateLayoutState()
                }
            }
        }
    }
    
    func loadData() {
        loadDataWithRetry(retryCount: 0)
    }
    
    private func showError(_ error: Error) {
        let errorContainer = UIView()
        errorContainer.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        errorContainer.layer.cornerRadius = 16
        
        let errorLabel = UILabel()
        errorLabel.text = "⚠️ " + error.localizedDescription
        errorLabel.font = .systemFont(ofSize: 20)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorContainer.addSubview(errorLabel)
        
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry".smb_localized, for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        retryButton.tintColor = .white
        retryButton.backgroundColor = .systemBlue
        retryButton.layer.cornerRadius = 12
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .primaryActionTriggered)
        errorContainer.addSubview(retryButton)
        
        view.addSubview(errorContainer)
        self.errorView = errorContainer
        
        errorLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
        
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(150)
            make.height.equalTo(50)
        }
        
        errorContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(500)
        }
    }
    
    @objc private func didTapRetry() {
        loadDataWithRetry()
    }
    
    private func updateLayoutState() {
        // Update status label
        if let activeHost = HSBHostsManager.shared.activeHost {
            statusLabel.text = String(format: "✓ Active: %@".smb_localized, activeHost)
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "No Hosts Enabled".smb_localized
            statusLabel.textColor = .systemGray
        }
        
        // Layout adjustment based on empty state
        tableView.isHidden = files.isEmpty
        
        if files.isEmpty {
            addBtn.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(400)
                make.height.equalTo(80)
            }
            addBtn.setTitle("Add Your First Hosts File".smb_localized, for: .normal)
        } else {
            addBtn.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(-40)
                make.centerX.equalToSuperview()
                make.height.equalTo(60)
                make.width.equalTo(300)
            }
            addBtn.setTitle("Add Hosts File".smb_localized, for: .normal)
        }
    }
    
    @objc private func didClickAdd() {
        onAddHost?()
    }
    
    // MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < files.count else {
            // Safety check
            return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! HSBHostsCell
        let filename = files[indexPath.row]
        let isActive = filename == HSBHostsManager.shared.activeHost
        cell.configure(filename: filename, isActive: isActive)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < files.count else { return }
        let filename = files[indexPath.row]
        onSelectHost?(filename)
    }
    
    // tvOS: Use context menu instead of swipe actions
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < files.count else { return nil }
        
        let filename = files[indexPath.row]
        let isActive = filename == HSBHostsManager.shared.activeHost
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            var actions: [UIAction] = []
            
            // Toggle Enable/Disable
            if isActive {
                let disableAction = UIAction(
                    title: "Disable".smb_localized,
                    image: UIImage(systemName: "xmark.circle"),
                    attributes: .destructive
                ) { [weak self] _ in
                    HSBHostsManager.shared.activeHost = nil
                    self?.loadData()
                }
                actions.append(disableAction)
            } else {
                let enableAction = UIAction(
                    title: "Enable".smb_localized,
                    image: UIImage(systemName: "checkmark.circle.fill")
                ) { [weak self] _ in
                    HSBHostsManager.shared.activeHost = filename
                    self?.loadData()
                    NotificationCenter.default.post(name: NSNotification.Name("HSBHostsDidUpdate"), object: nil)
                }
                actions.append(enableAction)
            }
            
            // Delete
            let deleteAction = UIAction(
                title: "Delete".smb_localized,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.confirmDelete(filename: filename)
            }
            actions.append(deleteAction)
            
            return UIMenu(title: filename, children: actions)
        }
    }
    
    private func confirmDelete(filename: String) {
        let alert = UIAlertController(
            title: "Delete Hosts File".smb_localized,
            message: String(format: "Are you sure you want to delete '%@'?".smb_localized, filename),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel".smb_localized, style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete".smb_localized, style: .destructive) { [weak self] _ in
            do {
                HSBHostsManager.shared.deleteHostsFile(filename: filename)
                self?.loadData()
            } catch {
                self?.showError(error)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - Custom Cell for tvOS
class HSBHostsCell: UITableViewCell {
    
    private let fileIcon = UIImageView()
    private let titleLabel = UILabel()
    private let statusBadge = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        fileIcon.image = UIImage(systemName: "doc.text.fill")
        fileIcon.tintColor = .systemBlue
        contentView.addSubview(fileIcon)
        
        titleLabel.font = .systemFont(ofSize: 28, weight: .medium)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)
        
        statusBadge.font = .systemFont(ofSize: 18, weight: .bold)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 8
        statusBadge.clipsToBounds = true
        contentView.addSubview(statusBadge)
        
        fileIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(fileIcon.snp.right).offset(20)
            make.centerY.equalToSuperview()
            make.right.equalTo(statusBadge.snp.left).offset(-20)
        }
        
        statusBadge.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(36)
        }
    }
    
    func configure(filename: String, isActive: Bool) {
        titleLabel.text = filename
        
        if isActive {
            statusBadge.text = "ACTIVE"
            statusBadge.backgroundColor = .systemGreen
            statusBadge.textColor = .white
            statusBadge.isHidden = false
            accessoryType = .checkmark
        } else {
            statusBadge.isHidden = true
            accessoryType = .disclosureIndicator
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        coordinator.addCoordinatedAnimations {
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            } else {
                self.transform = .identity
                self.backgroundColor = .clear
            }
        }
    }
}

// MARK: - Content View Controller
class HSBHostsContentViewController: UIViewController {
    
    private var textView: UITextView!
    private var titleLabel: UILabel!
    private var actionStack: UIStackView!
    private var enableBtn: UIButton!
    private var disableBtn: UIButton!
    private var deleteBtn: UIButton!
    
    private var currentFilename: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hostsDidUpdate),
            name: NSNotification.Name("HSBHostsDidUpdate"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func hostsDidUpdate() {
        if let filename = currentFilename {
            updateButtons(filename: filename)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        titleLabel = UILabel()
        titleLabel.font = .boldSystemFont(ofSize: 36)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Action buttons
        actionStack = UIStackView()
        actionStack.axis = .horizontal
        actionStack.spacing = 20
        actionStack.distribution = .fillEqually
        view.addSubview(actionStack)
        
        enableBtn = createActionButton(title: "Enable", icon: "checkmark.circle.fill", color: .systemGreen)
        enableBtn.addTarget(self, action: #selector(didTapEnable), for: .primaryActionTriggered)
        
        disableBtn = createActionButton(title: "Disable", icon: "xmark.circle.fill", color: .systemOrange)
        disableBtn.addTarget(self, action: #selector(didTapDisable), for: .primaryActionTriggered)
        
        deleteBtn = createActionButton(title: "Delete", icon: "trash.fill", color: .systemRed)
        deleteBtn.addTarget(self, action: #selector(didTapDelete), for: .primaryActionTriggered)
        
        actionStack.addArrangedSubview(enableBtn)
        actionStack.addArrangedSubview(disableBtn)
        actionStack.addArrangedSubview(deleteBtn)
        
        textView = UITextView()
        textView.font = .monospacedSystemFont(ofSize: 20, weight: .regular)
        textView.textColor = .green
        textView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        textView.isEditable = false
        textView.isSelectable = true
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.addSubview(textView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.left.right.equalToSuperview().inset(40)
        }
        
        actionStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(60)
            make.width.equalTo(700)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalTo(actionStack.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview().inset(40)
        }
        
        showEmptyState()
    }
    
    private func createActionButton(title: String, icon: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setImage(UIImage(systemName: icon), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        btn.tintColor = color
        btn.backgroundColor = color.withAlphaComponent(0.2)
        btn.layer.cornerRadius = 12
        return btn
    }
    
    private func showEmptyState() {
        titleLabel.text = "Select a hosts file"
        titleLabel.textColor = .systemGray
        textView.text = "No file selected.\n\nSelect a hosts file from the list to view its content."
        actionStack.isHidden = true
    }
    
    func loadContent(filename: String) {
        currentFilename = filename
        titleLabel.text = filename
        titleLabel.textColor = .white
        
        if let content = HSBHostsManager.shared.getHostsContent(filename: filename) {
            textView.text = content
        } else {
            textView.text = "Failed to load file content"
        }
        
        actionStack.isHidden = false
        updateButtons(filename: filename)
    }
    
    private func updateButtons(filename: String) {
        let isActive = filename == HSBHostsManager.shared.activeHost
        enableBtn.isHidden = isActive
        disableBtn.isHidden = !isActive
    }
    
    @objc private func didTapEnable() {
        guard let filename = currentFilename else { return }
        HSBHostsManager.shared.activeHost = filename
        updateButtons(filename: filename)
        NotificationCenter.default.post(name: NSNotification.Name("HSBHostsDidUpdate"), object: nil)
        showToast(message: "✓ '\(filename)' is now active")
    }
    
    @objc private func didTapDisable() {
        guard let filename = currentFilename else { return }
        HSBHostsManager.shared.activeHost = nil
        updateButtons(filename: filename)
        NotificationCenter.default.post(name: NSNotification.Name("HSBHostsDidUpdate"), object: nil)
        showToast(message: "Hosts disabled")
    }
    
    @objc private func didTapDelete() {
        guard let filename = currentFilename else { return }
        
        let alert = UIAlertController(
            title: "Delete Hosts File",
            message: "Are you sure you want to delete '\(filename)'?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            HSBHostsManager.shared.deleteHostsFile(filename: filename)
            self?.showEmptyState()
            NotificationCenter.default.post(name: NSNotification.Name("HSBHostsDidUpdate"), object: nil)
        })
        
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = .systemFont(ofSize: 24, weight: .semibold)
        toast.textColor = .white
        toast.backgroundColor = UIColor(white: 0.2, alpha: 0.95)
        toast.textAlignment = .center
        toast.layer.cornerRadius = 16
        toast.clipsToBounds = true
        toast.alpha = 0
        
        view.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
            make.width.equalTo(500)
            make.height.equalTo(60)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, animations: {
                toast.alpha = 0
            }, completion: { _ in
                toast.removeFromSuperview()
            })
        })
    }
}

// MARK: - Upload QR Code VC
class HSBHostsUploadQRCodeVC: UIViewController {
    
    private var qrImageView: UIImageView!
    private var urlLabel: UILabel!
    private var statusLabel: UILabel!
    private var closeBtn: UIButton!
    
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.95)
        setupUI()
        startServer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        HSBHostsManager.shared.stopServer()
        onDismiss?()
    }
    
    private func setupUI() {
        let title = UILabel()
        title.text = "Scan to Upload Hosts File"
        title.font = .systemFont(ofSize: 46, weight: .bold)
        title.textColor = .white
        view.addSubview(title)
        
        let instruction = UILabel()
        instruction.text = "Use your phone to scan the QR code and upload a hosts file"
        instruction.font = .systemFont(ofSize: 24)
        instruction.textColor = .systemGray
        instruction.numberOfLines = 0
        instruction.textAlignment = .center
        view.addSubview(instruction)
        
        qrImageView = UIImageView()
        qrImageView.layer.cornerRadius = 24
        qrImageView.clipsToBounds = true
        qrImageView.backgroundColor = .white
        view.addSubview(qrImageView)
        
        urlLabel = UILabel()
        urlLabel.textColor = .cyan
        urlLabel.font = .monospacedSystemFont(ofSize: 32, weight: .bold)
        urlLabel.textAlignment = .center
        view.addSubview(urlLabel)
        
        statusLabel = UILabel()
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 28, weight: .medium)
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
        
        closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Close", for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 28, weight: .semibold)
        closeBtn.tintColor = .white
        closeBtn.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        closeBtn.layer.cornerRadius = 12
        closeBtn.addTarget(self, action: #selector(didTapClose), for: .primaryActionTriggered)
        view.addSubview(closeBtn)
        
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(120)
            make.centerX.equalToSuperview()
        }
        
        instruction.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(800)
        }
        
        qrImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(450)
        }
        
        urlLabel.snp.makeConstraints { make in
            make.top.equalTo(qrImageView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(urlLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(700)
        }
        
        closeBtn.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-60)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(60)
        }
    }
    
    private func startServer() {
        if let ip = HSBHostsManager.shared.startServer() {
            let url = "http://\(ip):9971/"
            urlLabel.text = url
            generateQRCode(from: url)
            statusLabel.text = "Waiting for upload..."
            
            HSBHostsManager.shared.onReceiveHosts = { [weak self] filename in
                self?.statusLabel.text = "✓ File '\(filename)' received!"
                self?.statusLabel.textColor = .systemGreen
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            statusLabel.text = "⚠️ Server failed to start. Please check network settings."
            statusLabel.textColor = .systemRed
        }
    }
    
    @objc private func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
    
    private func generateQRCode(from string: String) {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        if let output = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaled = output.transformed(by: transform)
            if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
                qrImageView.image = UIImage(cgImage: cgImage)
            }
        }
    }
}
