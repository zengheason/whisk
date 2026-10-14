import AppKit
import Testing

@testable import Whisk

@MainActor
@Suite struct PanelScrollRouting {
    private final class RecordingScrollView: NSScrollView {
        var received: [NSEvent] = []
        override func scrollWheel(with event: NSEvent) { received.append(event) }
    }

    private func wheel(_ phase: NSEvent.Phase = [], momentum: NSEvent.Phase = []) throws -> NSEvent {
        let cg = try #require(
            CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 0, wheel2: 20, wheel3: 0))
        cg.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        let phaseValue: Int64 =
            phase.contains(.began) ? 1 : phase.contains(.changed) ? 2 : phase.contains(.ended) ? 4 : 0
        cg.setIntegerValueField(.scrollWheelEventScrollPhase, value: phaseValue)
        let momentumValue: Int64 =
            momentum.contains(.began) ? 1 : momentum.contains(.ended) ? 3 : momentum.isEmpty ? 0 : 2
        cg.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentumValue)
        let event = try #require(NSEvent(cgEvent: cg))
        #expect(event.phase == phase)
        #expect(event.momentumPhase == momentum)
        return event
    }

    @Test func rail_gaps_and_outside_points_receive_one_event_and_keep_its_identity() throws {
        defer { MouseActivity.lastScroll = .distantPast }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 400))
        let rail = RecordingScrollView(frame: NSRect(x: 0, y: 0, width: 900, height: 240))
        root.addSubview(rail)
        let router = PanelScrollRouter()
        for point in [CGPoint(x: 10, y: 80), CGPoint(x: 224, y: 80), CGPoint(x: 20, y: 330)] {
            let event = try wheel()
            router.route(event, in: root, at: point)
            #expect(rail.received.last === event)
        }
        #expect(rail.received.count == 3)
    }

    @Test func momentum_stays_on_the_original_rail_when_pointer_crosses_the_filter_strip() throws {
        defer { MouseActivity.lastScroll = .distantPast }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 400))
        let rail = RecordingScrollView(frame: NSRect(x: 0, y: 0, width: 900, height: 240))
        let filters = RecordingScrollView(frame: NSRect(x: 0, y: 280, width: 900, height: 40))
        root.addSubview(rail)
        root.addSubview(filters)
        let router = PanelScrollRouter()
        router.route(try wheel(.began), in: root, at: CGPoint(x: 20, y: 80))
        router.route(try wheel(.changed), in: root, at: CGPoint(x: 20, y: 290))
        router.route(try wheel(.ended), in: root, at: CGPoint(x: 20, y: 290))
        router.route(try wheel(momentum: .began), in: root, at: CGPoint(x: 20, y: 290))
        router.route(try wheel(momentum: .ended), in: root, at: CGPoint(x: 20, y: 290))
        #expect(rail.received.count == 5)
        #expect(filters.received.isEmpty)
        router.route(try wheel(.began), in: root, at: CGPoint(x: 20, y: 290))
        #expect(filters.received.count == 1)
        router.reset()
        router.route(try wheel(.changed), in: root, at: CGPoint(x: 20, y: 80))
        #expect(rail.received.count == 6)
    }

    @Test func a_panel_delivers_each_wheel_event_once_before_the_responder_chain() throws {
        let panel = FloatingPanel()
        var received = 0
        let event = try wheel()
        panel.scrollHandler = { incoming in
            #expect(incoming === event)
            received += 1
        }
        panel.sendEvent(event)
        #expect(received == 1)
    }

    @Test func an_empty_or_replaced_rail_does_not_retain_a_stale_gesture_target() throws {
        defer { MouseActivity.lastScroll = .distantPast }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 400))
        let first = RecordingScrollView(frame: root.bounds)
        root.addSubview(first)
        let router = PanelScrollRouter()
        router.route(try wheel(.began), in: root, at: CGPoint(x: 20, y: 80))
        first.removeFromSuperview()
        router.route(try wheel(.changed), in: root, at: CGPoint(x: 20, y: 80))
        #expect(first.received.count == 1)
        let replacement = RecordingScrollView(frame: root.bounds)
        root.addSubview(replacement)
        router.route(try wheel(.changed), in: root, at: CGPoint(x: 20, y: 80))
        #expect(replacement.received.count == 1)
    }

    @Test func recent_scrolling_blocks_hover_even_when_the_pointer_has_moved() {
        let now = Date()
        MouseActivity.lastMove = now
        MouseActivity.lastScroll = now
        #expect(!MouseActivity.movedRecently)
        #expect(MouseActivity.scrollingRecently)
        MouseActivity.lastScroll = .distantPast
        #expect(MouseActivity.movedRecently)
        #expect(!MouseActivity.scrollingRecently)
        MouseActivity.lastMove = .distantPast
    }
}
