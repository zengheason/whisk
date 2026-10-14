import Foundation

enum GroupColor: String, Codable, CaseIterable {
    case blue, purple, pink, orange, green, teal
}

struct ClipboardGroup: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let color: GroupColor

    init?(id: UUID = UUID(), name: String, color: GroupColor = .blue) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.id = id
        self.name = trimmed
        self.color = color
    }

    private enum CodingKeys: String, CodingKey { case id, name, color }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        color = try values.decodeIfPresent(GroupColor.self, forKey: .color) ?? .blue
    }
}
