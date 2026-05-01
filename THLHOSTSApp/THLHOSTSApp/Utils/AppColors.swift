import UIKit

// MARK: - Dynamic Colors
extension UIColor {
    
    static var appBackground: UIColor {
        return UIColor(hex: "#020617") // Deepest Midnight
    }
    
    static var appPrimary: UIColor {
        return UIColor(hex: "#0F172A") // Slate 900
    }
    
    static var appSecondary: UIColor {
        return UIColor(hex: "#1E293B") // Slate 800
    }
    
    static var appText: UIColor {
        return UIColor(hex: "#F1F5F9") // Slate 100 (Bright Text)
    }
    
    static var appCTA: UIColor {
        return UIColor(hex: "#6A8DFA") // Primary Blue
    }
    
    static var appAccent: UIColor {
        return UIColor(hex: "#6A8DFA").withAlphaComponent(0.8)
    }
    
    static var appMutedText: UIColor {
        return UIColor(hex: "#64748B") // Slate 500
    }
}

// MARK: - Hex Initialization helper
extension UIColor {
    convenience init(hex: String) {
        let hexHash = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexHash).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexHash.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
import SwiftUI

extension Color {
    static var appBackground: Color { Color(uiColor: .appBackground) }
    static var appPrimary: Color { Color(uiColor: .appPrimary) }
    static var appSecondary: Color { Color(uiColor: .appSecondary) }
    static var appText: Color { Color(uiColor: .appText) }
    static var appCTA: Color { Color(uiColor: .appCTA) }
    static var appMutedText: Color { Color(uiColor: .appMutedText) }
}
