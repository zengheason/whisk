import Foundation

/// Opaque representations, grouped by pasteboard item. Restoring the
/// original bytes lets the receiving app choose the same format it would
/// have chosen immediately after the source application's copy.
struct OriginalPasteboardContents: Codable, Equatable, Hashable {
    let items: [[Representation]]

    struct Representation: Codable, Equatable, Hashable {
        let type: String
        let data: Data
    }
}
