import Foundation

@objc public class HSBHostsLanguageManager: NSObject {
    @objc public static let shared = HSBHostsLanguageManager()
    
    private let kUserLanguageKey = "HSBUserLanguageKey"
    
    @objc public var currentLanguage: String {
        get {
            // Default to system language if not set, or fallback to "en"
            if let saved = UserDefaults.standard.string(forKey: kUserLanguageKey) {
                return saved
            }
            let lang = Locale.preferredLanguages.first ?? "en"
            if lang.hasPrefix("zh") {
                return "zh-Hans"
            }
            return "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kUserLanguageKey)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: NSNotification.Name("HSBLanguageChanged"), object: nil)
        }
    }
    
    @objc public func localizedString(_ key: String) -> String {
        var lang = currentLanguage
        // Handle variations of zh-Hans if needed, but for now strict match
        
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to Base or en if bundle not found
             if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
                let bundle = Bundle(path: path) {
                 return bundle.localizedString(forKey: key, value: nil, table: nil)
             }
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
