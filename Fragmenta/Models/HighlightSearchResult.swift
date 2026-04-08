import Foundation

struct HighlightSearchResult: Codable, Identifiable, Hashable, Sendable {
    let highlight: Highlight
    let book: BookReference
    let matchedTerms: [String]

    var id: String {
        highlight.id
    }
}
