import AppKit
import Carbon.HIToolbox
import Testing

@testable import Whisk

/// The panel's windows, created but never ordered in: nothing here puts
/// anything on screen.
@MainActor
@Suite struct PanelWindowing {
    @Test func the_input_shield_routes_scroll_but_consumes_swipes_and_dismisses_only_on_click() throws {
        var scrolls = 0
        var dismissals = 0
        let shield = PanelInputShield(
            frame: NSRect(x: 0, y: 0, width: 900, height: 600),
            onScroll: { _ in scrolls += 1 }, onDismiss: { dismissals += 1 })
        defer { shield.close() }
        let view = try #require(shield.contentView as? PanelInputShieldView)
        let wheel = try #require(
            CGEvent(
                scrollWheelEvent2Source: nil, units: .pixel,
                wheelCount: 2, wheel1: 0, wheel2: 60, wheel3: 0))
        let event = try #require(NSEvent(cgEvent: wheel))
        view.scrollWheel(with: event)
        view.swipe(with: event)
        view.magnify(with: event)
        #expect(scrolls == 1)
        #expect(dismissals == 0)
        #expect(!shield.ignoresMouseEvents)
        #expect(!shield.canBecomeKey)
        view.mouseDown(with: event)
        #expect(dismissals == 1)
    }

    @Test func an_internal_drag_keeps_the_panel_open_when_it_resigns_key() {
        _ = NSApplication.shared
        let panel = FloatingPanel()
        panel.setFrame(NSRect(x: -10000, y: -10000, width: 300, height: 100), display: false)
        panel.isReleasedWhenClosed = false
        defer { panel.close() }
        var closes = 0
        panel.onClose = { closes += 1 }
        panel.orderFront(nil)
        panel.resignKey()
        #expect(panel.isVisible)
        #expect(closes == 0)
        panel.resignKey()
        #expect(panel.isVisible)
        panel.cancelOperation(nil)
        #expect(!panel.isVisible)
        #expect(closes == 1)
    }

    @Test func modifier_changes_reach_the_hint_state_without_triggering_a_selection() throws {
        _ = NSApplication.shared
        let panel = FloatingPanel()
        let state = HistoryViewStateStore()
        var selections = 0
        panel.keyHandler = { _ in
            selections += 1; return true
        }
        panel.modifiersChanged = { state.setCommandHeld($0.contains(.command)) }
        for flags: NSEvent.ModifierFlags in [[.command], []] {
            let event = try #require(
                NSEvent.keyEvent(
                    with: .flagsChanged, location: .zero,
                    modifierFlags: flags, timestamp: 0, windowNumber: panel.windowNumber, context: nil,
                    characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: UInt16(kVK_Command)))
            panel.sendEvent(event)
            #expect(state.commandHeld == flags.contains(.command))
        }
        #expect(selections == 0)
    }
    @Test func the_floating_panel_hands_keys_to_its_handler_and_closes_on_the_second_cancel() throws {
        _ = NSApplication.shared
        let panel = FloatingPanel()
        var handled: [UInt16] = []
        var cancels = 0
        var closes = 0
        panel.keyHandler = { event in
            handled.append(event.keyCode)
            return true
        }
        panel.onCancel = {
            cancels += 1
            return cancels == 1
        }
        panel.onClose = { closes += 1 }
        let press = try #require(aKeyEvent(kVK_ANSI_H, typing: "h"))

        panel.sendEvent(press)
        panel.cancelOperation(nil)
        panel.cancelOperation(nil)
        panel.resignKey()

        #expect(handled == [UInt16(kVK_ANSI_H)])
        #expect(panel.canBecomeKey)
        #expect(cancels == 2)
        #expect(closes == 0)
        #expect(!panel.isVisible)
    }

    @Test func the_panel_rises_on_the_screen_under_the_pointer_or_the_primary_one() {
        let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let secondary = CGRect(x: 1920, y: 200, width: 1440, height: 900)

        #expect(PanelController.screenIndex(under: CGPoint(x: 100, y: 100), frames: [primary, secondary]) == 0)
        #expect(PanelController.screenIndex(under: CGPoint(x: 2500, y: 600), frames: [primary, secondary]) == 1)
        #expect(PanelController.screenIndex(under: CGPoint(x: -50, y: 5000), frames: [primary, secondary]) == 0)
        #expect(PanelController.screenIndex(under: .zero, frames: []) == nil)
    }

    @Test func the_panel_controller_hides_idempotently_and_ignores_drags_while_hidden() throws {
        _ = NSApplication.shared
        let sandbox = try IsolatedDefaults()
        let store = HistoryViewStateStore()
        let spy = PanelActionSpy()
        let controller = PanelController(
            stateStore: store, actions: spy.actions, keyBindings: KeyBindingsStore(defaults: sandbox.defaults),
            vimBindings: VimBindingsStore(defaults: sandbox.defaults), vimMode: { false })

        controller.hide()
        controller.dragDidBegin()
        controller.hide()

        #expect(spy.calls.isEmpty)
        #expect(store.closeRevision == 0)
    }

    @Test func a_display_change_while_the_panel_is_hidden_touches_nothing() throws {
        _ = NSApplication.shared
        let sandbox = try IsolatedDefaults()
        let store = HistoryViewStateStore()
        let spy = PanelActionSpy()
        let controller = PanelController(
            stateStore: store, actions: spy.actions, keyBindings: KeyBindingsStore(defaults: sandbox.defaults),
            vimBindings: VimBindingsStore(defaults: sandbox.defaults), vimMode: { false })

        NotificationCenter.default.post(name: NSApplication.didChangeScreenParametersNotification, object: NSApp)

        #expect(spy.calls.isEmpty)
        #expect(store.closeRevision == 0)
        #expect(store.focusRevision == 0)
        withExtendedLifetime(controller) {}
    }
}
