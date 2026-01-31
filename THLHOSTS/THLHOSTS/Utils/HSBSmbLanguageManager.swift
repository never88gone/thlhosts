
import Foundation

public enum HSBSmbLanguage: String {
    case chinese = "zh"
    case english = "en"
}

public class HSBSmbLanguageManager {
    public static let shared = HSBSmbLanguageManager()
    
    private let kUserLanguageKey = "HSBSmbUserLanguageKey"
    
    public var currentLanguage: HSBSmbLanguage {
        get {
            // Priority: User Setting -> System Language -> English
            if let saved = UserDefaults.standard.string(forKey: kUserLanguageKey),
               let lang = HSBSmbLanguage(rawValue: saved) {
                return lang
            }
            
            // Auto detect from system
            let langStr = Locale.preferredLanguages.first ?? "en"
            if langStr.hasPrefix("zh") {
                return .chinese
            }
            return .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kUserLanguageKey)
            // Post notification if UI needs to update immediately
            NotificationCenter.default.post(name: NSNotification.Name("HSBSmbLanguageChanged"), object: nil)
        }
    }
    
    public func localizedString(_ key: String) -> String {
        // Determine the lproj folder name
        // Apple uses "zh-Hans" for Simplified Chinese
        let langCode = currentLanguage == .chinese ? "zh-Hans" : "en"
        
        // Identify the bundle where this class (and resources) are located
        let hostBundle = Bundle(for: HSBSmbLanguageManager.self)
        
        // Try to find the specific language bundle path
        if let path = hostBundle.path(forResource: langCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            // Load string from that bundle
            return NSLocalizedString(key, tableName: "Localizable", bundle: bundle, value: key, comment: "")
        }
        
        // Fallback to host bundle (usually Base or dev lang)
        return NSLocalizedString(key, tableName: "Localizable", bundle: hostBundle, value: key, comment: "")
    }
}

// MARK: - String Extension
public extension String {
    /// Auto convert to current language based on HSBSmbLanguageManager
    var smb_localized: String {
        return HSBSmbLanguageManager.shared.localizedString(self)
    }
}
