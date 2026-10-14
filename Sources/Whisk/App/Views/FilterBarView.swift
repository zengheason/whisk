import AppKit
import SwiftUI

/// One chip row above the search field, three groups separated by thin
/// bars — the pinned toggle, then source applications, then content
/// categories. Several chips can be active at once; the focused chip is
/// the keyboard cursor (↑/↓ reach the row, ←/→ move, Return toggles) and
/// hovering moves that same focus with the mouse.
struct FilterBarView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The viewport's width, so a row that fits can be stretched to it.
    @State private var dropTargets: Set<UUID> = []
    @State private var rowWidth: CGFloat = 0
    private static let horizontalMargin: CGFloat = 16
    let filters: FilterBarViewState
    var editorStore: HistoryViewStateStore?
    var editorActions: PanelActions?
    /// One cursor at a time: vim's search mode swallows the chip focus.
    var cursorSuppressed = false
    let onToggleApp: (String) -> Void
    let onToggleKind: (String) -> Void
    let onFocusApp: (String) -> Void
    let onFocusKind: (String) -> Void
    var onToggleGroup: (UUID) -> Void = { _ in }
    var onCreateGroup: () -> Void = {}
    var onRenameGroup: (UUID) -> Void = { _ in }
    var onDeleteGroup: (UUID) -> Void = { _ in }
    var onAddToGroup: (UUID, UUID) -> Void = { _, _ in }
    var onSetGroupColor: (UUID, GroupColor) -> Void = { _, _ in }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters.pinned) { chip in
                        ChipButton(
                            chip: chip,
                            focusVisible: !cursorSuppressed,
                            onToggle: { onToggleKind(chip.id) },
                            onFocus: { onFocusKind(chip.id) }
                        ) {
                            HStack(spacing: 5) {
                                chipIcon(chip.icon)
                                Text(chip.label)
                            }
                        }
                        .id(chip.id)
                    }
                    if !filters.pinned.isEmpty
                        && !(filters.apps.isEmpty && filters.kinds.isEmpty && filters.groups.isEmpty)
                    {
                        separator
                    }
                    ForEach(filters.apps) { chip in
                        ChipButton(
                            chip: chip,
                            baseTint: SourceAppStyle.resolve(bundleID: chip.sourceBundleID)
                                .surfaceTint(dark: scheme == .dark),
                            focusVisible: !cursorSuppressed,
                            onToggle: { onToggleApp(chip.id) },
                            onFocus: { onFocusApp(chip.id) }
                        ) {
                            HStack(spacing: 5) {
                                if let icon = SourceAppStyle.resolve(bundleID: chip.sourceBundleID).icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 17, height: 17)
                                }
                                Text(chip.label)
                            }
                        }
                        .id(chip.id)
                    }
                    if !filters.apps.isEmpty && !filters.kinds.isEmpty {
                        separator
                    }
                    ForEach(filters.kinds) { chip in
                        ChipButton(
                            chip: chip,
                            focusVisible: !cursorSuppressed,
                            onToggle: { onToggleKind(chip.id) },
                            onFocus: { onFocusKind(chip.id) }
                        ) {
                            HStack(spacing: 5) {
                                chipIcon(chip.icon)
                                Text(chip.label)
                            }
                        }
                        .id(chip.id)
                    }
                    if !filters.groups.isEmpty
                        && !(filters.apps.isEmpty && filters.kinds.isEmpty && filters.pinned.isEmpty)
                    {
                        separator
                    }
                    ForEach(filters.groups) { chip in
                        if let editorStore, let editorActions, editorStore.groupEditorOpen,
                            editorStore.editingGroupID == chip.groupID
                        {
                            GroupEditorView(store: editorStore, actions: editorActions, color: chip.color)
                                .id(chip.id)
                        } else {
                            ChipButton(
                                chip: chip, baseTint: chip.color.tint.opacity(0.25), focusVisible: !cursorSuppressed,
                                onToggle: { if let id = chip.groupID { onToggleGroup(id) } },
                                onFocus: { onFocusKind(chip.id) }
                            ) {
                                HStack(spacing: 5) {
                                    Circle().fill(chip.color.tint).frame(width: 9, height: 9)
                                    Text(chip.label)
                                }
                            }
                            .id(chip.id)
                            .overlay(
                                Capsule().stroke(
                                    chip.color.tint,
                                    lineWidth: chip.groupID.map { dropTargets.contains($0) } == true ? 3 : 0)
                            )
                            .onDrop(
                                of: [CardDragIdentity.type],
                                isTargeted: Binding(
                                    get: { chip.groupID.map { dropTargets.contains($0) } ?? false },
                                    set: { active in
                                        guard let id = chip.groupID else { return }
                                        if active { dropTargets.insert(id) } else { dropTargets.remove(id) }
                                    }
                                )
                            ) { providers in
                                guard let id = chip.groupID, !providers.isEmpty else { return false }
                                if let itemID = CardDragIdentity.activeItemID {
                                    onAddToGroup(itemID, id)
                                    return true
                                }
                                for provider in providers {
                                    _ = provider.loadDataRepresentation(
                                        forTypeIdentifier: CardDragIdentity.type.identifier
                                    ) { data, _ in
                                        guard let data, let text = String(data: data, encoding: .utf8),
                                            let itemID = UUID(uuidString: text)
                                        else { return }
                                        DispatchQueue.main.async { onAddToGroup(itemID, id) }
                                    }
                                }
                                return true
                            }
                            .contextMenu {
                                if let id = chip.groupID {
                                    Menu(localized("Group Color")) {
                                        ForEach(GroupColor.allCases, id: \.self) { color in
                                            Button {
                                                onSetGroupColor(id, color)
                                            } label: {
                                                Label(
                                                    color.label,
                                                    systemImage: color == chip.color
                                                        ? "checkmark.circle.fill" : "circle.fill"
                                                )
                                                .foregroundStyle(color.tint)
                                            }
                                        }
                                    }
                                    Button(localized("Rename Group…")) { onRenameGroup(id) }
                                    Button(localized("Delete Group"), role: .destructive) { onDeleteGroup(id) }
                                }
                            }
                        }
                    }
                    if let editorStore, let editorActions, editorStore.groupEditorOpen,
                        editorStore.editingGroupID == nil
                    {
                        GroupEditorView(store: editorStore, actions: editorActions)
                            .id("new-group-editor")
                    }
                    Button(action: onCreateGroup) {
                        Label(localized("New Group…"), systemImage: "plus")
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .liquidGlass(in: Capsule())
                    .help(localized("Drag a card onto a group to save it."))
                }
                .padding(.vertical, 3)
                // Centered under the search capsule while the chips fit: a
                // scroll view hugs the leading edge otherwise. Stretched to
                // the viewport, the stack centers its content; a wider row
                // scrolls as before.
                .frame(minWidth: max(0, rowWidth - 2 * Self.horizontalMargin))
            }
            .contentMargins(.horizontal, Self.horizontalMargin, for: .scrollContent)
            .scrollClipDisabled()
            .defaultScrollAnchor(.center)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { rowWidth = geometry.size.width }
                        .onChange(of: geometry.size.width) { _, width in rowWidth = width }
                }
            }
            .onChange(of: editorStore?.groupEditorOpen) { _, open in
                if open == true {
                    proxy.scrollTo(editorStore?.editingGroupID.map { "group:\($0.uuidString)" } ?? "new-group-editor")
                }
            }
            .onChange(of: filters.focusedChipID) { _, id in
                guard let id else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
                    proxy.scrollTo(id)
                }
            }
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.25))
            .frame(width: 1, height: 16)
            .padding(.horizontal, 4)
            .accessibilityHidden(true)
    }

    @ViewBuilder private func chipIcon(_ icon: ChipIcon?) -> some View {
        switch icon {
        case .resource(let name, let fallback):
            if let image = CategoryIcons.image(named: name) {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                symbol(fallback)
            }
        case .symbol(let name):
            symbol(name)
        case nil:
            EmptyView()
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
    }
}

/// One chip. Like the cards: hovering moves the shared keyboard focus onto
/// it, and focus or an active filter zooms it slightly.
private struct ChipButton<Label: View>: View {
    let chip: FilterChip
    var baseTint: Color?
    var focusVisible = true
    let onToggle: () -> Void
    let onFocus: () -> Void
    @ViewBuilder let label: () -> Label
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color { chip.groupID == nil ? .matcha : chip.color.tint }

    private var isFocused: Bool {
        chip.isFocused && focusVisible
    }

    private var zoomed: Bool {
        isFocused || chip.isActive
    }

    var body: some View {
        Button(action: onToggle) {
            label()
        }
        .buttonStyle(FilterChipStyle(isActive: chip.isActive, isFocused: isFocused, accent: accent))
        .accessibilityLabel(chip.accessibilityLabel)
        .accessibilityAddTraits(chip.isActive ? .isSelected : [])
        .linkPointer()
        .scaleEffect(zoomed ? 1.06 : 1)
        // The frosted capsule is an AppKit view and ignores transforms, so
        // it grows geometrically in a measured background — oversize does
        // not push neighbors — while the content scales above it.
        .background {
            GeometryReader { proxy in
                Color.clear
                    .liquidGlass(
                        in: Capsule(),
                        tint: chip.isActive ? accent.opacity(0.28) : baseTint
                    )
                    .frame(
                        width: proxy.size.width * (zoomed ? 1.06 : 1),
                        height: proxy.size.height * (zoomed ? 1.06 : 1)
                    )
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isFocused)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: chip.isActive)
        .onContinuousHover { phase in
            if case .active = phase, MouseActivity.movedRecently {
                onFocus()
            }
        }
    }
}

private struct FilterChipStyle: ButtonStyle {
    let isActive: Bool
    let isFocused: Bool
    var accent: Color = .matcha

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(isActive ? .semibold : .regular))
            .foregroundStyle(isActive ? accent : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                Capsule().strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }

    private var borderColor: Color {
        if isFocused {
            return accent
        }
        if isActive {
            return accent.opacity(0.8)
        }
        return .clear
    }
}
