import Foundation

struct ClipboardGroup: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String

    init?(id: UUID = UUID(), name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.id = id
        self.name = trimmed
    }
}
