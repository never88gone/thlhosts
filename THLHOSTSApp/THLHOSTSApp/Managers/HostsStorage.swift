
import Foundation

class HostsStorage {
    static let shared = HostsStorage()
    private let key = "SavedHostsFiles"
    
    func save(_ files: [HostsFile]) {
        if let data = try? JSONEncoder().encode(files) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func load() -> [HostsFile] {
        if let data = UserDefaults.standard.data(forKey: key),
           let files = try? JSONDecoder().decode([HostsFile].self, from: data) {
            return files
        }
        return []
    }
}
