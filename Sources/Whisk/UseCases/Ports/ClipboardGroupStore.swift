import Foundation

protocol ClipboardGroupStore {
    func load() throws -> [ClipboardGroup]
    func save(_ groups: [ClipboardGroup]) throws
}
