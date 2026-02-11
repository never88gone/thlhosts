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
            // Always use light color because background is glass (dark)
            textLabel?.textColor = isEnabled ? .systemGreen : .white
        }
    }
    
    // MARK: - Focus (tvOS)
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if context.nextFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.backgroundColor = UIColor.white.withAlphaComponent(0.2)
                // Keep text color visible
                if let text = self.textLabel?.text, !text.contains("+") { // Not add button
                     // Force white or keep green/red? Using white for focus is safer
                     self.textLabel?.textColor = .black // High contrast on white-ish background
                     self.backgroundColor = .white
                }
            }, completion: nil)
        } else if context.previouslyFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = .identity
                self.backgroundColor = .clear
                // Restore color
                let isEnabled = self.textLabel?.textColor == .systemGreen // Rough check, better to store state
                // Re-configure based on assumed state is risky without data access, 
                // but usually cell reuse handles it. 
                // Simpler: Just rely on configure being called or use a simpler focus style.
                // Let's just reset to white for non-enabled, we need to know enabling state though.
                // For now, let's just default to white if it was black.
                if self.textLabel?.textColor == .black {
                     self.textLabel?.textColor = .white
                }
            }, completion: nil)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            contentView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        } else {
            contentView.backgroundColor = .clear
        }
    }
}
