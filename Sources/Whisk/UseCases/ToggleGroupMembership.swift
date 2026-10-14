import Foundation

struct ToggleGroupMembership<Store: HistoryStore> {
    let store: Store

    func callAsFunction(_ groupID: UUID, for itemID: UUID, in history: History) throws -> History {
        let next = history.togglingGroup(groupID, for: itemID)
        try store.save(next.items)
        return next
    }
}
