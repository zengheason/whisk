import Foundation

final class JSONClipboardGroupStore: ClipboardGroupStore {
    private let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() throws -> [ClipboardGroup] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let decoded = try JSONDecoder().decode([ClipboardGroup].self, from: Data(contentsOf: fileURL))
        var ids: Set<UUID> = []
        return decoded.compactMap { group in
            guard ids.insert(group.id).inserted else { return nil }
            return ClipboardGroup(id: group.id, name: group.name)
        }
    }

    func save(_ groups: [ClipboardGroup]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(groups).write(to: fileURL, options: .atomic)
    }
}
