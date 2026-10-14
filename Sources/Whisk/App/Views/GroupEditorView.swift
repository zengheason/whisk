import SwiftUI

/// Edits a chip in place without replacing the history rail.
struct GroupEditorView: View {
    @ObservedObject var store: HistoryViewStateStore
    let actions: PanelActions
    var color: GroupColor = .blue
    @FocusState private var nameFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color.tint).frame(width: 10, height: 10)
            TextField(localized("Group name"), text: Binding(get: { store.groupName }, set: store.setGroupName))
                .textFieldStyle(.plain)
                .focused($nameFocused)
                .onSubmit { store.saveGroup(using: actions) }
                .onExitCommand { store.endGroupEditing() }
                .frame(width: 130)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .textBackgroundColor), in: Capsule())
        .overlay(Capsule().stroke(store.groupError == nil ? color.tint : .red, lineWidth: 2))
        .help(store.groupError ?? localized("Group name"))
        .onAppear { nameFocused = true }
    }
}
