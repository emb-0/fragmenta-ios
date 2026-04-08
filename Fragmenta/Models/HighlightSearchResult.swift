import Foundation

struct HighlightSearchResult: Codable, Identifiable, Hashable, Sendable {
    let highlight: Highlight
    let book: BookReference
    let matchedTerms: [String]
    let snippet: String?
    let matchedInNote: Bool?
    let matchedField: String?

    var id: String {
        highlight.id
    }

    var displaySnippet: String {
        if let snippet, snippet.trimmed.isEmpty == false {
            return snippet.trimmed
        }

        return highlight.text.trimmed
    }
}
