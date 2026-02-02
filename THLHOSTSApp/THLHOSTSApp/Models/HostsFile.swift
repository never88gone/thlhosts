
import Foundation

struct HostsFile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var content: String
    var isEnabled: Bool
}
