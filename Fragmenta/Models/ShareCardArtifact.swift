import Foundation

struct ShareCardArtifact: Hashable, Identifiable, Sendable {
    let highlightID: String
    let fileURL: URL
    let generatedAt: Date
    let byteCount: Int
    let mimeType: String?

    var id: String { highlightID }
}
