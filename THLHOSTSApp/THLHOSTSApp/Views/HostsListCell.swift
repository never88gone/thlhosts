import UIKit
import SnapKit

class HostsListCell: UITableViewCell {
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private var isAddButton: Bool = false
    private var isEnabledHost: Bool = false

    private func setupView() {
        backgroundColor = .clear
        textLabel?.adjustsFontSizeToFitWidth = true
        #if os(tvOS)
        textLabel?.font = UIFont.systemFont(ofSize: 31, weight: .medium) // [ZH] tvOS 最小 31pt
        #else
        if DeviceHelper.isPadOrMac {
            textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        } else {
            textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        }
        #endif
    }
    
    // MARK: - Configuration
    func configure(text: String, isAddButton: Bool = false, isEnabled: Bool = false) {
        textLabel?.text = text
        self.isAddButton = isAddButton
        self.isEnabledHost = isEnabled
        updateAppearance(isFocused: isFocused)
    }

    private func updateAppearance(isFocused: Bool) {
        if isAddButton {
            // Add Button Style
            #if os(tvOS)
            if isFocused {
                backgroundColor = .appText
                textLabel?.textColor = .appBackground
            } else {
                backgroundColor = .clear
                textLabel?.textColor = .systemBlue
            }
            #else
            textLabel?.textColor = .systemBlue
            backgroundColor = .clear
            #endif
        } else {
            // Normal Item Style
            #if os(tvOS)
            if isFocused {
                backgroundColor = .appText
                textLabel?.textColor = .appBackground
            } else {
                backgroundColor = .clear
                textLabel?.textColor = isEnabledHost ? .appCTA : .appText
            }
            #else
            textLabel?.textColor = isEnabledHost ? .appCTA : .appText
            backgroundColor = .clear
            #endif
        }
    }
    
    // MARK: - Focus (tvOS)
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if context.nextFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.updateAppearance(isFocused: true)
            }, completion: nil)
        } else if context.previouslyFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = .identity
                self.updateAppearance(isFocused: false)
            }, completion: nil)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            contentView.backgroundColor = UIColor.appSecondary.withAlphaComponent(0.6)
        } else {
            contentView.backgroundColor = .clear
        }
    }
}
