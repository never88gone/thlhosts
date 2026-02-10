import UIKit

/// A view that implements the "Liquid Glass" effect (tvOS 26 / iOS 26 style).
/// This style features high translucency, subtle blurring, and a premium "liquid" feel.
@objc class HSBLiquidGlassView: UIView {
    
    // MARK: - Properties
    
    private let blurView: UIVisualEffectView = {
        let effect: UIBlurEffect
        #if os(tvOS)
        if #available(tvOS 13.0, *) {
            effect = UIBlurEffect(style: .regular)
        } else {
            effect = UIBlurEffect(style: .light)
        }
        #else
        if #available(iOS 13.0, *) {
            effect = UIBlurEffect(style: .systemThinMaterial)
        } else {
            effect = UIBlurEffect(style: .light)
        }
        #endif
        return UIVisualEffectView(effect: effect)
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(white: 1.0, alpha: 0.15).cgColor,
            UIColor(white: 1.0, alpha: 0.05).cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        layer.cornerRadius = 20
        layer.masksToBounds = true
        layer.borderWidth = 1.0
        layer.borderColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        
        // Add Blur
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurView)
        
        // Add Gradient Overlay
        layer.addSublayer(gradientLayer)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
