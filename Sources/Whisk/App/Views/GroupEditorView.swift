import SwiftUI

struct GroupEditorView: View {
    @ObservedObject var store: HistoryViewStateStore
    let actions: PanelActions
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.editingGroupID == nil ? localized("New Group…") : localized("Rename Group…"))
                .font(.headline)
            TextField(localized("Group name"), text: Binding(get: { store.groupName }, set: store.setGroupName))
                .textFieldStyle(.roundedBorder)
                .focused($nameFocused)
            if let error = store.groupError {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            Text(localized("Drag a card onto a group to save it."))
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button(localized("Cancel")) { store.endGroupEditing() }
                Button(localized("Save")) { store.saveGroup(using: actions) }
                    .disabled(store.groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous), cornerRadius: 22)
        .padding(.horizontal, 16)
        .onAppear { nameFocused = true }
    }
}
