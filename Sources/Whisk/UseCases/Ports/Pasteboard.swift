import Foundation

/// What the system pasteboard held when a change was observed. Rich text
/// travels as opaque RTF bytes next to the plain payload.
struct PasteboardSnapshot: Equatable {
    let payload: Payload
    let source: SourceApp?
    let rtf: Data?
    let originalContents: OriginalPasteboardContents?

    init(payload: Payload, source: SourceApp?, rtf: Data? = nil, originalContents: OriginalPasteboardContents? = nil) {
        self.payload = payload
        self.source = source
        self.rtf = rtf
        self.originalContents = originalContents
    }
}

/// Boundary to the system pasteboard.
protocol Pasteboard {
    /// A snapshot when the pasteboard changed since the previous call, nil otherwise.
    func readIfChanged() -> PasteboardSnapshot?
    func write(_ payload: Payload, rtf: Data?, originalContents: OriginalPasteboardContents?)
}

extension Pasteboard {
    func write(_ payload: Payload, rtf: Data?) {
        write(payload, rtf: rtf, originalContents: nil)
    }
}
