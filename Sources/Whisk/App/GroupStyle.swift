import SwiftUI
import UniformTypeIdentifiers

extension GroupColor {
    var tint: Color {
        switch self {
        case .blue: Color(red: 0.08, green: 0.36, blue: 0.94)
        case .purple: Color(red: 0.48, green: 0.18, blue: 0.88)
        case .pink: Color(red: 0.85, green: 0.10, blue: 0.36)
        case .orange: Color(red: 0.78, green: 0.27, blue: 0.02)
        case .green: Color(red: 0.10, green: 0.48, blue: 0.16)
        case .teal: Color(red: 0.0, green: 0.46, blue: 0.52)
        }
    }
}

enum CardDragIdentity {
    static func attach(_ itemID: UUID, to provider: NSItemProvider) {
        provider.registerDataRepresentation(forTypeIdentifier: type.identifier, visibility: .all) { completion in
            completion(Data(itemID.uuidString.utf8), nil)
            return nil
        }
    }

    static var activeItemID: UUID?
    static let type = UTType(exportedAs: "app.whisk.history-card", conformingTo: .data)
}
