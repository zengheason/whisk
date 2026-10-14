import SwiftUI
import UniformTypeIdentifiers

extension GroupColor {
    var tint: Color {
        switch self {
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        case .orange: .orange
        case .green: .green
        case .teal: .teal
        }
    }
}

enum CardDragIdentity {
    static let type = UTType(exportedAs: "app.whisk.history-card")
}
