import AppKit

/// One destination owns the complete gesture, including momentum across gaps and windows.
final class PanelScrollRouter {
    private weak var gestureTarget: NSScrollView?
    private weak var rail: NSScrollView?

    func route(_ event: NSEvent, in root: NSView, at point: CGPoint) {
        MainActor.assumeIsolated { MouseActivity.lastScroll = Date() }
        if let gestureTarget, !gestureTarget.isDescendant(of: root) { self.gestureTarget = nil }
        let phased = !event.phase.isEmpty || !event.momentumPhase.isEmpty
        if event.phase.contains(.began) || !phased { gestureTarget = nil }
        let target = gestureTarget ?? scrollView(under: point, in: root) ?? cardRail(in: root)
        if phased { gestureTarget = target }
        target?.scrollWheel(with: event)
        if event.phase.contains(.cancelled) || event.momentumPhase.contains(.ended) { gestureTarget = nil }
    }

    func reset() {
        gestureTarget = nil
        rail = nil
    }

    private func scrollView(under point: CGPoint, in root: NSView) -> NSScrollView? {
        var view = root.hitTest(point)
        while let current = view {
            if let scroll = current as? NSScrollView { return scroll }
            view = current.superview
        }
        return nil
    }

    private func cardRail(in root: NSView) -> NSScrollView? {
        if let rail, rail.isDescendant(of: root) { return rail }
        func descendants(_ view: NSView) -> [NSScrollView] {
            (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap(descendants)
        }
        rail = descendants(root).max(by: { $0.frame.height < $1.frame.height })
        return rail
    }
}
