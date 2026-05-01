import UIKit

// MARK: - Dynamic Colors
extension UIColor {
    
    static var appBackground: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#020617") // Deepest Midnight
        case .hackerTerminal: return UIColor(hex: "#000000") // True Black
        case .cleanLight:     return UIColor(hex: "#F8FAFC")
        }
    }
    
    static var appPrimary: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#0F172A") // Slate 900
        case .hackerTerminal: return UIColor(hex: "#0A0A0A") // Near Black
        case .cleanLight:     return UIColor(hex: "#FFFFFF")
        }
    }
    
    static var appSecondary: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#1E293B") // Slate 800
        case .hackerTerminal: return UIColor(hex: "#171717") // Zinc 900
        case .cleanLight:     return UIColor(hex: "#E2E8F0")
        }
    }
    
    static var appText: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#F1F5F9") // Slate 100
        case .hackerTerminal: return UIColor(hex: "#00FF41") // Matrix Green
        case .cleanLight:     return UIColor(hex: "#0F172A")
        }
    }
    
    static var appCTA: UIColor {
        return UIColor(hex: "#6A8DFA") // New Primary Color
    }
    
    static var appAccent: UIColor {
        return UIColor(hex: "#6A8DFA").withAlphaComponent(0.8)
    }
    
    static var appMutedText: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#64748B") // Slate 500
        case .hackerTerminal: return UIColor(hex: "#404040") // Dark Gray
        case .cleanLight:     return UIColor(hex: "#94A3B8")
        }
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
