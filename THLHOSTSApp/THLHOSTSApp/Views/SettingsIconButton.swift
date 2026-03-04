import UIKit

/// A custom UIControl subclass that supports tvOS focus, showing a `gearshape.fill` icon
/// with animated scale + tint changes on focus.
class SettingsIconButton: UIControl {

    // MARK: - Properties
    private let imageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)
        iv.image = UIImage(systemName: "gearshape.fill", withConfiguration: config)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .appText
        iv.backgroundColor = .clear
        iv.isUserInteractionEnabled = false
        return iv
    }()

    // MARK: - Focus
    override var canBecomeFocused: Bool { return true }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    // MARK: - tvOS Focus Animation
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if context.nextFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                self.imageView.tintColor = .appCTA
                self.imageView.alpha = 1.0
            }, completion: nil)
        } else if context.previouslyFocusedView == self {
            coordinator.addCoordinatedAnimations({
                self.transform = .identity
                self.imageView.tintColor = .appText
                self.imageView.alpha = 0.85
            }, completion: nil)
        }
    }

    // MARK: - Tint passthrough
    override var tintColor: UIColor! {
        didSet {
            imageView.tintColor = tintColor
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
        #if os(tvOS)
        if presses.contains(where: { $0.type == .select }) {
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        }
        #endif
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        #if os(tvOS)
        if presses.contains(where: { $0.type == .select }) {
            UIView.animate(withDuration: 0.12) {
                self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }
            sendActions(for: .primaryActionTriggered)
        }
        #endif
    }
}
