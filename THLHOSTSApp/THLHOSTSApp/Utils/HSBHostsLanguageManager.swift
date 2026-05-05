import Foundation

@objc public class HSBHostsLanguageManager: NSObject {
    @objc public static let shared = HSBHostsLanguageManager()
    
    private let kUserLanguageKey = "app_language"
    
    @objc public var currentLanguage: String {
        get {
            // Check if user has explicitly set a language
            if let saved = UserDefaults.standard.string(forKey: kUserLanguageKey), saved != "system" {
                return saved
            }
            
            // Fallback to system language
            let lang = Locale.preferredLanguages.first ?? "en"
            if lang.hasPrefix("zh") {
                return "zh-Hans"
            }
            return "en"
        }
        set {
            setLanguage(newValue)
        }
    }
    
    @objc public func setLanguage(_ language: String) {
        if language == "system" {
            UserDefaults.standard.removeObject(forKey: kUserLanguageKey)
        } else {
            UserDefaults.standard.set(language, forKey: kUserLanguageKey)
        }
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name("HSBLanguageChanged"), object: nil)
    }
    
    @objc public func localizedString(_ key: String) -> String {
        var lang = currentLanguage
        // Ensure we use the mapped code for bundle lookup
        let bundleLang = lang.contains("zh") ? "zh-Hans" : "en"
        
        guard let path = Bundle.main.path(forResource: bundleLang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
             if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                let bundle = Bundle(path: path) {
                 return bundle.localizedString(forKey: key, value: nil, table: nil)
             }
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension String {
    var localized: String {
        return HSBHostsLanguageManager.shared.localizedString(self)
    }
}
