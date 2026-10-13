import AppKit
import Testing

@testable import Whisk

/// The gateway over a private pasteboard of its own, released when the
/// test ends — the general pasteboard is never touched.
@MainActor
@Suite struct AppKitPasteboardCapture {
    private final class PrivateBoard {
        let board: NSPasteboard

        init() {
            board = NSPasteboard(name: NSPasteboard.Name("whisk-tests-\(UUID().uuidString)"))
        }

        deinit {
            board.releaseGlobally()
        }
    }

    private static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    @Test func an_unchanged_pasteboard_yields_nothing() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)

        #expect(gateway.readIfChanged() == nil)
    }

    @Test func a_string_is_captured_once_per_change() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        sandbox.board.clearContents()
        sandbox.board.setString("hello", forType: .string)

        #expect(gateway.readIfChanged()?.payload == .text("hello"))
        #expect(gateway.readIfChanged() == nil)
    }

    @Test func a_bare_web_address_becomes_a_link_but_prose_around_one_stays_text() throws {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let url = try #require(URL(string: "https://example.com/path"))

        sandbox.board.clearContents()
        sandbox.board.setString(" https://example.com/path\n", forType: .string)
        #expect(gateway.readIfChanged()?.payload == .link(url))

        sandbox.board.clearContents()
        sandbox.board.setString("see https://example.com/path please", forType: .string)
        #expect(gateway.readIfChanged()?.payload == .text("see https://example.com/path please"))
    }

    @Test func concealed_content_is_never_captured() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        sandbox.board.declareTypes([.string, Self.concealed], owner: nil)
        sandbox.board.setString("hunter2", forType: .string)
        sandbox.board.setString("", forType: Self.concealed)

        #expect(gateway.readIfChanged() == nil)
    }

    @Test func rich_text_travels_beside_the_plain_text() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let rtf = Data("{\\rtf1 hello}".utf8)
        sandbox.board.declareTypes([.string, .rtf], owner: nil)
        sandbox.board.setString("hello", forType: .string)
        sandbox.board.setData(rtf, forType: .rtf)

        let snapshot = gateway.readIfChanged()

        #expect(snapshot?.payload == .text("hello"))
        #expect(snapshot?.rtf == rtf)
    }

    @Test func file_urls_win_over_everything_else() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        sandbox.board.clearContents()
        sandbox.board.writeObjects([NSURL(fileURLWithPath: "/tmp/a.txt"), NSURL(fileURLWithPath: "/tmp/b.txt")])

        #expect(gateway.readIfChanged()?.payload == .fileReferences(["/tmp/a.txt", "/tmp/b.txt"]))
    }

    @Test func png_is_captured_as_is_and_tiff_is_normalized_to_png() throws {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let bitmap = try #require(
            NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        let tiff = try #require(bitmap.tiffRepresentation)

        sandbox.board.clearContents()
        sandbox.board.setData(png, forType: .png)
        #expect(gateway.readIfChanged()?.payload == .image(png))

        sandbox.board.clearContents()
        sandbox.board.setData(tiff, forType: .tiff)
        guard case .image(let normalized)? = gateway.readIfChanged()?.payload else {
            Issue.record("expected an image")
            return
        }
        #expect(normalized.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47]))
    }

    @Test func a_board_holding_only_foreign_types_yields_nothing() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let foreign = NSPasteboard.PasteboardType("com.example.opaque-blob")
        sandbox.board.declareTypes([foreign], owner: nil)
        sandbox.board.setData(Data([0x01, 0x02]), forType: foreign)

        #expect(gateway.readIfChanged() == nil)
    }

    @Test func the_copy_is_attributed_to_a_regular_frontmost_app_or_to_the_menu_bar_owner() throws {
        let finder = try #require(
            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first)

        #expect(AppKitPasteboard.attributedSource(frontmost: finder, menuBarOwner: nil) == finder)
        #expect(AppKitPasteboard.attributedSource(frontmost: nil, menuBarOwner: finder) == finder)
        #expect(AppKitPasteboard.attributedSource(frontmost: nil, menuBarOwner: nil) == nil)
    }

    @Test func own_writes_are_not_captured_again() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)

        gateway.write(.text("from whisk"), rtf: nil)

        #expect(sandbox.board.string(forType: .string) == "from whisk")
        #expect(gateway.readIfChanged() == nil)
    }

    @Test func writing_puts_each_payload_kind_on_the_board() throws {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let url = try #require(URL(string: "https://example.com"))
        let rtf = Data("{\\rtf1 hi}".utf8)

        gateway.write(.text("hi"), rtf: rtf)
        #expect(sandbox.board.string(forType: .string) == "hi")
        #expect(sandbox.board.data(forType: .rtf) == rtf)

        gateway.write(.link(url), rtf: nil)
        #expect(sandbox.board.string(forType: .string) == "https://example.com")
        #expect(sandbox.board.data(forType: .rtf) == nil)

        gateway.write(.image(Data([0x89, 0x50])), rtf: nil)
        #expect(sandbox.board.data(forType: .png) == Data([0x89, 0x50]))

        gateway.write(.fileReferences(["/tmp/a.txt"]), rtf: nil)
        let urls =
            sandbox.board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL]
        #expect(urls?.map(\.path) == ["/tmp/a.txt"])
    }

    @Test func original_html_rtf_custom_formats_and_item_boundaries_survive_a_restart_and_copy() throws {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = directory.appendingPathComponent("history.sqlite")
        let store = try SQLiteHistoryStore(databaseURL: database)
        let first = NSPasteboardItem()
        first.setString("Heading\nA\tB", forType: .string)
        first.setData(
            Data("<h1 style='color:red'>Heading</h1><table><tr><td>A</td><td>B</td></tr></table>".utf8), forType: .html)
        first.setData(Data("{\\rtf1\\b Heading\\b0\\par A\\tab B}".utf8), forType: .rtf)
        let custom = NSPasteboard.PasteboardType("com.example.table")
        first.setData(Data([1, 2, 3]), forType: custom)
        let second = NSPasteboardItem()
        second.setString("second item", forType: .string)
        sandbox.board.clearContents()
        sandbox.board.writeObjects([first, second])
        let originalPlain = sandbox.board.string(forType: .string)
        let original = sandbox.board.pasteboardItems?.map { item in
            Dictionary(
                uniqueKeysWithValues: item.types.compactMap { type in
                    item.data(forType: type).map { (type.rawValue, $0) }
                })
        }
        let history = try CaptureClipboardChange(pasteboard: gateway, clock: FakeClock(), store: store)(into: History())
        #expect(history.items.first?.originalContents != nil)
        let reopened = try SQLiteHistoryStore(databaseURL: database)
        let reloaded = try LoadHistory(store: reopened)()
        let item = try #require(reloaded.items.first)
        _ = try SelectItem(pasteboard: gateway, clock: FakeClock(), store: reopened)(item.id, in: reloaded)
        let restored = sandbox.board.pasteboardItems?.map { item in
            Dictionary(
                uniqueKeysWithValues: item.types.compactMap { type in
                    item.data(forType: type).map { (type.rawValue, $0) }
                })
        }
        #expect(restored == original)
        #expect(gateway.readIfChanged() == nil)
        _ = try SelectItem(pasteboard: gateway, clock: FakeClock(), store: reopened)(item.id, in: reloaded, plain: true)
        #expect(sandbox.board.string(forType: .string) == originalPlain)
        #expect(sandbox.board.data(forType: .html) == nil)
        #expect(sandbox.board.data(forType: custom) == nil)
    }

    @Test func a_copied_link_keeps_its_original_whitespace_and_rich_format() throws {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let original = " https://example.com/path\n"
        let html = Data("<a href='https://example.com/path'>https://example.com/path</a>".utf8)
        sandbox.board.clearContents()
        sandbox.board.setString(original, forType: .string)
        sandbox.board.setData(html, forType: .html)
        let snapshot = try #require(gateway.readIfChanged())
        gateway.write(snapshot.payload, rtf: snapshot.rtf, originalContents: snapshot.originalContents)
        #expect(sandbox.board.string(forType: .string) == original)
        #expect(sandbox.board.data(forType: .html) == html)
    }

    @Test func concealed_markers_on_later_items_also_prevent_capture() {
        let sandbox = PrivateBoard()
        let gateway = AppKitPasteboard(board: sandbox.board)
        let first = NSPasteboardItem()
        first.setString("ordinary", forType: .string)
        let second = NSPasteboardItem()
        second.setString("secret", forType: .string)
        second.setString("", forType: Self.concealed)
        sandbox.board.clearContents()
        sandbox.board.writeObjects([first, second])
        #expect(gateway.readIfChanged() == nil)
    }
}
