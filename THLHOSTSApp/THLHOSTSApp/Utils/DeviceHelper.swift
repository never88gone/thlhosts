import UIKit

struct DeviceHelper {
    static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        }
        return false
        #endif
    }
    
    static var isPadOrMac: Bool {
        return isPad || isMac
    }
    
    static var isTV: Bool {
        return UIDevice.current.userInterfaceIdiom == .tv
    }
    
    static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}
