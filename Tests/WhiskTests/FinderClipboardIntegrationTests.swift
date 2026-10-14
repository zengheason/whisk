import AppKit
import Testing

@testable import Whisk

/// Opt-in bridge for the manual Finder test. Only the disposable fixture is accepted.
@MainActor
@Suite struct FinderClipboardIntegration {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["WHISK_FINDER_ROUNDTRIP"] == "1"))
    func finder_fixture_survives_history_storage_before_native_move() throws {
        let general = NSPasteboard.general
        let urls = try #require(
            general.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]) as? [URL])
        try #require(
            !urls.isEmpty
                && urls.allSatisfy {
                    $0.path.hasPrefix("/tmp/WhiskNativeClipboardCheck/")
                        || $0.path.hasPrefix("/private/tmp/WhiskNativeClipboardCheck/")
                })
        let privateBoard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        defer { privateBoard.releaseGlobally() }
        let capture = AppKitPasteboard(board: privateBoard)
        let replicas = (general.pasteboardItems ?? []).map { original in
            let item = NSPasteboardItem()
            for type in original.types {
                if let bytes = original.data(forType: type) { item.setData(bytes, forType: type) }
            }
            return item
        }
        privateBoard.clearContents()
        try #require(privateBoard.writeObjects(replicas))
        let snapshot = try #require(capture.readIfChanged())
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let database = folder.appendingPathComponent("history.sqlite")
        let item = ClipboardItem(
            id: UUID(), payload: snapshot.payload, source: snapshot.source,
            copiedAt: .distantPast, isPinned: false, rtf: snapshot.rtf, originalContents: snapshot.originalContents)
        try SQLiteHistoryStore(databaseURL: database).save([item])
        let loaded = try #require(SQLiteHistoryStore(databaseURL: database).load().first)
        #expect(loaded == item)
        AppKitPasteboard(board: general).write(
            loaded.payload, rtf: loaded.rtf, originalContents: loaded.originalContents)
        let restored = general.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
        #expect(restored == urls)
    }
}
