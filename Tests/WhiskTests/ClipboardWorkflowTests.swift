import AppKit
import Testing

@testable import Whisk

@Suite struct ClipboardWorkflowImprovements {
    @Test func choosing_a_group_replaces_the_previous_group_and_choosing_it_again_clears() throws {
        let store = InMemoryHistoryStore()
        store.stored = [anItem(.text("first")), anItem(.text("second"))]
        let spy = ClipboardControllerBehaviour.StateSpy()
        let controller = ClipboardController(
            pasteboard: ScriptedPasteboard(), store: store,
            clock: FakeClock(), logger: RecordingLogger(), present: spy.record)
        #expect(controller.createGroup("A"))
        #expect(controller.createGroup("B"))
        let a = spy.last.groups[0].id
        let b = spy.last.groups[1].id
        controller.addToGroup(store.stored[0].id, groupID: a)
        controller.addToGroup(store.stored[1].id, groupID: b)
        controller.toggleGroupFilter(a)
        controller.toggleGroupFilter(b)
        #expect(spy.last.filters.groups.filter(\.isActive).map(\.groupID) == [b])
        #expect(spy.last.cards.map(\.preview) == [.text("second")])
        controller.toggleGroupFilter(b)
        #expect(!spy.last.filters.groups.contains { $0.isActive })
        #expect(spy.last.cards.count == 2)
    }

    @Test func drag_identity_is_available_to_the_native_drop_provider() async throws {
        let id = UUID()
        let provider = NSItemProvider(object: "Example" as NSString)
        CardDragIdentity.attach(id, to: provider)
        #expect(provider.hasItemConformingToTypeIdentifier(CardDragIdentity.type.identifier))
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            _ = provider.loadDataRepresentation(forTypeIdentifier: CardDragIdentity.type.identifier) { data, error in
                if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: error ?? CocoaError(.fileReadUnknown))
                }
            }
        }
        #expect(String(data: data, encoding: .utf8) == id.uuidString)
    }

    @Test func legacy_groups_receive_a_color_and_new_colors_survive_renaming() throws {
        let id = UUID()
        let data = Data("{\"id\":\"\(id)\",\"name\":\"Legacy\"}".utf8)
        let legacy = try JSONDecoder().decode(ClipboardGroup.self, from: data)
        #expect(legacy.color == .blue)
        let store = InMemoryHistoryStore()
        let item = anItem(.text("saved"))
        store.stored = [item]
        let spy = ClipboardControllerBehaviour.StateSpy()
        let controller = ClipboardController(
            pasteboard: ScriptedPasteboard(), store: store,
            clock: FakeClock(), logger: RecordingLogger(), present: spy.record)
        #expect(controller.createGroup("First"))
        #expect(controller.createGroup("Second"))
        let first = try #require(spy.last.groups.first)
        #expect(first.color != spy.last.groups.last?.color)
        controller.addToGroup(item.id, groupID: first.id)
        controller.addToGroup(item.id, groupID: first.id)
        #expect(store.stored.first?.groupIDs == [first.id])
        #expect(controller.renameGroup(first.id, name: "Renamed"))
        #expect(spy.last.groups.first?.color == first.color)
    }

    @Test func copying_is_the_default_and_both_preferences_survive_restart() throws {
        let sandbox = try IsolatedDefaults()
        let settings = GeneralSettingsStore(defaults: sandbox.defaults)
        #expect(!settings.pasteAutomatically)
        #expect(settings.glassEnabled)
        settings.pasteAutomatically = true
        settings.glassEnabled = false
        let reloaded = GeneralSettingsStore(defaults: sandbox.defaults)
        #expect(reloaded.pasteAutomatically)
        #expect(!reloaded.glassEnabled)
    }

    @Test func command_hints_follow_modifier_changes_and_clear_when_the_panel_closes() {
        let state = HistoryViewStateStore()
        state.setCommandHeld(true)
        #expect(state.shortcutHint(at: 0) == "⌘1")
        #expect(state.shortcutHint(at: 8) == "⌘9")
        #expect(state.shortcutHint(at: 9) == nil)
        state.setCommandHeld(false)
        #expect(state.shortcutHint(at: 0) == nil)
        state.setCommandHeld(true)
        state.panelDidClose()
        #expect(state.shortcutHint(at: 0) == nil)
    }

    @Test func saving_or_cancelling_a_group_editor_returns_focus_to_search() {
        let state = HistoryViewStateStore()
        var actions = PanelActionSpy().actions
        var created: [String] = []
        var renamed: [String] = []
        actions.createGroup = {
            created.append($0); return true
        }
        actions.renameGroup = { _, name in
            renamed.append(name); return true
        }
        state.beginGroupEditing()
        state.setGroupName("常用")
        state.saveGroup(using: actions)
        #expect(created == ["常用"])
        #expect(!state.groupEditorOpen)
        #expect(state.focusRevision == 1)
        state.beginGroupEditing(GroupViewState(id: UUID(), label: "常用"))
        state.setGroupName("报价")
        state.saveGroup(using: actions)
        #expect(renamed == ["报价"])
        #expect(state.focusRevision == 2)
        state.beginGroupEditing()
        state.endGroupEditing()
        #expect(state.focusRevision == 3)
    }

    @Test func group_memberships_survive_storage_and_protect_saved_items_from_housekeeping() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try SQLiteHistoryStore(databaseURL: directory.appendingPathComponent("history.sqlite"))
        let catalog = JSONClipboardGroupStore(fileURL: directory.appendingPathComponent("groups.json"))
        let group = try #require(ClipboardGroup(name: "  常用报价  "))
        let saved = anItem(.text("quote")).togglingGroup(group.id)
        try store.save([saved])
        try catalog.save([group])
        #expect(try store.load() == [saved])
        #expect(try catalog.load() == [group])
        let history = History(items: [anItem(.text("new")), saved], capacity: try #require(HistoryCapacity(1)))
        #expect(history.items.count == 2)
        #expect(history.clearingUnpinned().items == [saved])
        #expect(history.removingUnpinned(olderThan: .distantFuture).items == [saved])
        #expect(history.recording(.text("quote"), from: nil, at: .distantFuture).items.first?.groupIDs == [group.id])
        #expect(saved.replacing(payload: .text("updated")).groupIDs == [group.id])
    }

    @Test func groups_can_be_created_renamed_filtered_removed_and_reloaded() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let catalog = JSONClipboardGroupStore(fileURL: directory.appendingPathComponent("groups.json"))
        let history = InMemoryHistoryStore()
        history.stored = [anItem(.text("quote")), anItem(.text("other"))]
        let spy = ClipboardControllerBehaviour.StateSpy()
        let controller = ClipboardController(
            pasteboard: ScriptedPasteboard(), store: history, clock: FakeClock(), groupStore: catalog,
            logger: RecordingLogger(), present: spy.record)
        #expect(controller.createGroup("常用"))
        #expect(!controller.createGroup(" 常用 "))
        #expect(!controller.createGroup(" \n "))
        let group = try #require(spy.last.groups.first)
        let quote = history.stored[0].id
        controller.toggleGroupMembership(quote, groupID: group.id)
        controller.toggleGroupFilter(group.id)
        #expect(spy.last.cards.map(\.preview) == [.text("quote")])
        #expect(spy.last.filters.groups.first?.isActive == true)
        controller.focusCategoryChip("group:\(group.id.uuidString)")
        #expect(!controller.activateFocused())
        #expect(spy.last.cards.count == 2)
        #expect(controller.renameGroup(group.id, name: "报价"))
        #expect(try catalog.load().first?.name == "报价")
        let reloadedSpy = ClipboardControllerBehaviour.StateSpy()
        let reloaded = ClipboardController(
            pasteboard: ScriptedPasteboard(), store: history, clock: FakeClock(), groupStore: catalog,
            logger: RecordingLogger(), present: reloadedSpy.record)
        reloaded.toggleGroupFilter(group.id)
        #expect(reloadedSpy.last.cards.map(\.preview) == [.text("quote")])
        #expect(reloadedSpy.last.groups.first?.label == "报价")
        controller.clear()
        #expect(history.stored.map(\.payload) == [.text("quote")])
        controller.deleteGroup(group.id)
        #expect(spy.last.groups.isEmpty)
        #expect(history.stored.first?.groupIDs.isEmpty == true)
        #expect(history.stored.first?.payload == .text("quote"))
        #expect(try catalog.load().isEmpty)
    }

    @Test func a_corrupt_catalog_cannot_be_silently_overwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("groups.json")
        let broken = Data("broken".utf8)
        try broken.write(to: file)
        let logger = RecordingLogger()
        let controller = ClipboardController(
            pasteboard: ScriptedPasteboard(), store: InMemoryHistoryStore(), clock: FakeClock(),
            groupStore: JSONClipboardGroupStore(fileURL: file), logger: logger, present: { _ in })
        #expect(!controller.createGroup("new"))
        #expect(try Data(contentsOf: file) == broken)
        #expect(logger.messages.count == 1)
    }

    @Test func multiple_groups_use_or_and_compose_with_search_and_categories() throws {
        let a = UUID()
        let b = UUID()
        let quote = anItem(.text("quote")).togglingGroup(a)
        let address = anItem(.link(try #require(URL(string: "https://example.com")))).togglingGroup(b)
        let history = History(items: [quote, address, anItem(.text("unsaved"))])
        #expect(FilterHistory()(history, filter: HistoryFilter(groupIDs: [a, b])) == [quote, address])
        #expect(FilterHistory()(history, filter: HistoryFilter(query: "quo", groupIDs: [a, b])) == [quote])
        #expect(FilterHistory()(history, filter: HistoryFilter(categories: [.link], groupIDs: [a, b])) == [address])
        #expect(FilterHistory()(history, filter: HistoryFilter(groupIDs: [UUID()])).isEmpty)
    }

    @Test func identical_words_with_different_formats_keep_their_own_originals() throws {
        let bold = OriginalPasteboardContents(items: [[.init(type: "public.html", data: Data("<b>hello</b>".utf8))]])
        let italic = OriginalPasteboardContents(items: [[.init(type: "public.html", data: Data("<i>hello</i>".utf8))]])
        let date = FakeClock().now()
        let history = History()
            .recording(.text("hello"), from: nil, originalContents: bold, at: date)
            .recording(.text("hello"), from: nil, originalContents: italic, at: date)
        #expect(history.items.count == 2)
        let repeated = history.recording(.text("hello"), from: nil, originalContents: bold, at: date)
        #expect(repeated.items.count == 2)
        #expect(repeated.items.first?.id == history.items.last?.id)
        #expect(repeated.items.map(\.originalContents) == [bold, italic])
    }

    @Test func editing_drops_old_formats_on_disk_and_undo_restores_them() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = directory.appendingPathComponent("history.sqlite")
        let store = try SQLiteHistoryStore(databaseURL: database)
        let original = OriginalPasteboardContents(items: [[.init(type: "public.html", data: Data("<b>hello</b>".utf8))]]
        )
        let item = ClipboardItem(
            id: UUID(), payload: .text("hello"), source: nil, copiedAt: FakeClock().now(),
            isPinned: false, rtf: Data("rich".utf8), originalContents: original)
        try store.save([item])
        let edited = try EditItem(store: store)(item.id, text: "edited", in: History(items: [item]))
        #expect(try SQLiteHistoryStore(databaseURL: database).load().first?.payload == .text("edited"))
        #expect(try store.load().first?.originalContents == nil)
        #expect(try store.load().first?.rtf == nil)
        #expect(edited.items.first?.originalContents == nil)
        _ = try RestoreHistory(store: store)(History(items: [item]))
        #expect(try SQLiteHistoryStore(databaseURL: database).load() == [item])
    }

    @Test func the_paste_stack_preserves_formats_and_explicit_transforms_strip_them() {
        let board = ScriptedPasteboard()
        let store = InMemoryHistoryStore()
        let original = OriginalPasteboardContents(items: [[.init(type: "public.html", data: Data("<b>hello</b>".utf8))]]
        )
        let item = ClipboardItem(
            id: UUID(), payload: .text("hello"), source: nil, copiedAt: FakeClock().now(),
            isPinned: false, originalContents: original)
        store.stored = [item]
        let controller = ClipboardController(pasteboard: board, store: store, clock: FakeClock(), present: { _ in })
        controller.toggleStack(item.id)
        #expect(controller.popStack())
        #expect(board.writtenOriginalContents == [original])
        controller.select(item.id, transform: .uppercase)
        #expect(board.writtenOriginalContents == [original, nil])
        #expect(board.written.last == .text("HELLO"))
    }
}
