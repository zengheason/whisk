import AppKit

/// Owns pointer gestures while the clipboard is open, including outside its rail.
final class PanelInputShield: NSPanel {
    init(frame: NSRect, onScroll: @escaping (NSEvent) -> Void, onDismiss: @escaping () -> Void) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isReleasedWhenClosed = false
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = NSColor.black.withAlphaComponent(0.001)
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        contentView = PanelInputShieldView(onScroll: onScroll, onDismiss: onDismiss)
    }

    override var canBecomeKey: Bool { false }
}

final class PanelInputShieldView: NSView {
    private let onScroll: (NSEvent) -> Void
    private let onDismiss: () -> Void

    init(onScroll: @escaping (NSEvent) -> Void, onDismiss: @escaping () -> Void) {
        self.onScroll = onScroll
        self.onDismiss = onDismiss
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func scrollWheel(with event: NSEvent) { onScroll(event) }
    override func swipe(with event: NSEvent) {}
    override func magnify(with event: NSEvent) {}
    override func rotate(with event: NSEvent) {}
    override func mouseDown(with event: NSEvent) { onDismiss() }
    override func rightMouseDown(with event: NSEvent) { onDismiss() }
}
