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
    private func setupView() {
        backgroundColor = .clear
        textLabel?.adjustsFontSizeToFitWidth = true
    }
    
    // MARK: - Configuration
    func configure(text: String, isAddButton: Bool = false, isEnabled: Bool = false) {
        textLabel?.text = text
        
        if isAddButton {
            // Add Button Style
            if #available(tvOS 13.0, *), #available(iOS 13.0, *) {
                textLabel?.textColor = .systemBlue
            } else {
                textLabel?.textColor = .blue
            }
        } else {
            // Normal Item Style
            if #available(tvOS 13.0, *), #available(iOS 13.0, *) {
                textLabel?.textColor = isEnabled ? .systemGreen : .label
            } else {
                textLabel?.textColor = isEnabled ? .green : .darkGray
            }
        }
    }
    
    // MARK: - Focus (tvOS)
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if context.nextFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
            }, completion: nil)
        } else if context.previouslyFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = .identity
                self.backgroundColor = .clear
            }, completion: nil)
        }
    }
}
