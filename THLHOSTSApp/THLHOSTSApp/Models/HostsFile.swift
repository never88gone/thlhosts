
import Foundation

struct HostsFile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var content: String
    var isEnabled: Bool
    var sourceURL: String?
}
