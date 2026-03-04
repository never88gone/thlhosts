import UIKit

// MARK: - Dynamic Colors
extension UIColor {
    
    static var appBackground: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#0F172A")
        case .hackerTerminal: return UIColor(hex: "#020617")
        case .cleanLight:     return UIColor(hex: "#F8FAFC")
        }
    }
    
    static var appPrimary: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#1E293B")
        case .hackerTerminal: return UIColor(hex: "#0F172A")
        case .cleanLight:     return UIColor(hex: "#FFFFFF")
        }
    }
    
    static var appSecondary: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#334155")
        case .hackerTerminal: return UIColor(hex: "#1E293B")
        case .cleanLight:     return UIColor(hex: "#E2E8F0")
        }
    }
    
    static var appText: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#F8FAFC")
        case .hackerTerminal: return UIColor(hex: "#F8FAFC") // Bright white
        case .cleanLight:     return UIColor(hex: "#0F172A") // Dark slate
        }
    }
    
    static var appCTA: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#22C55E")
        case .hackerTerminal: return UIColor(hex: "#00FF41") // Neon green
        case .cleanLight:     return UIColor(hex: "#0891B2") // Cyan
        }
    }
    
    static var appMutedText: UIColor {
        switch ThemeManager.shared.currentTheme {
        case .developerDark:  return UIColor(hex: "#94A3B8")
        case .hackerTerminal: return UIColor(hex: "#475569")
        case .cleanLight:     return UIColor(hex: "#64748B")
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
