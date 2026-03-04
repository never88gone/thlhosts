import Foundation
import UIKit

// MARK: - Pre-defined Themes
enum AppTheme: String, CaseIterable {
    case developerDark = "Developer Dark"
    case hackerTerminal = "Hacker Terminal"
    case cleanLight = "Clean Light"
    
    // [ZH] 本地化名称
    var localizedName: String {
        switch self {
        case .developerDark: return HSBHostsLanguageManager.shared.localizedString("Developer Dark")
        case .hackerTerminal: return HSBHostsLanguageManager.shared.localizedString("Hacker Terminal")
        case .cleanLight: return HSBHostsLanguageManager.shared.localizedString("Clean Light")
        }
    }
}

// MARK: - Theme Notification
extension Notification.Name {
    static let themeChanged = Notification.Name("HSBThemeChanged")
}

// MARK: - Theme Manager
class ThemeManager {
    static let shared = ThemeManager()
    
    private let themeKey = "HSBCurrentAppTheme"
    
    private init() {
        if let savedThemeString = UserDefaults.standard.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedThemeString) {
            _currentTheme = savedTheme
        } else {
            _currentTheme = .developerDark
        }
    }
    
    private var _currentTheme: AppTheme
    
    var currentTheme: AppTheme {
        get { return _currentTheme }
        set {
            if _currentTheme != newValue {
                _currentTheme = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
                NotificationCenter.default.post(name: .themeChanged, object: nil)
            }
        }
    }
}
