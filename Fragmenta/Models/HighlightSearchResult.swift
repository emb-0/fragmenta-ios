import Foundation

struct HighlightSearchResult: Codable, Identifiable, Hashable, Sendable {
    let highlight: Highlight
    let book: BookReference
    let matchedTerms: [String]
    let snippet: String?
    let matchedInNote: Bool?
    let matchedField: String?
    let matchReason: String?
    let semanticScore: Double?

    init(
        highlight: Highlight,
        book: BookReference,
        matchedTerms: [String] = [],
        snippet: String? = nil,
        matchedInNote: Bool? = nil,
        matchedField: String? = nil,
        matchReason: String? = nil,
        semanticScore: Double? = nil
    ) {
        self.highlight = highlight
        self.book = book
        self.matchedTerms = matchedTerms
        self.snippet = snippet?.trimmed.nilIfBlank
        self.matchedInNote = matchedInNote
        self.matchedField = matchedField?.trimmed.nilIfBlank
        self.matchReason = matchReason?.trimmed.nilIfBlank
        self.semanticScore = semanticScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let decodedBook = try container.decodeIfPresent(BookReference.self, forKey: AnyCodingKey("book"))
        let decodedHighlight = try container.decodeIfPresent(Highlight.self, forKey: AnyCodingKey("highlight"))
            ?? Highlight(
                id: try container.decode(String.self, forKey: AnyCodingKey("id")),
                bookID: decodedBook?.id ?? "",
                text: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("text")) ?? "",
                note: try container.decodeFirstPresent(String.self, keys: ["note", "note_text"]),
                location: nil,
                page: nil,
                chapter: nil,
                colorName: nil,
                highlightedAt: try container.decodeFirstPresent(Date.self, keys: ["highlighted_at", "created_at"]),
                createdAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at")),
                updatedAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("updated_at")),
                book: decodedBook
            )

        let resolvedBook = decodedBook
            ?? decodedHighlight.book
            ?? BookReference(id: decodedHighlight.bookID, title: "Unknown book", author: nil)

        let resolvedHighlight = decodedHighlight.book == nil
            ? Highlight(
                id: decodedHighlight.id,
                bookID: decodedHighlight.bookID,
                text: decodedHighlight.text,
                note: decodedHighlight.note,
                location: decodedHighlight.location,
                page: decodedHighlight.page,
                chapter: decodedHighlight.chapter,
                colorName: decodedHighlight.colorName,
                highlightedAt: decodedHighlight.highlightedAt,
                createdAt: decodedHighlight.createdAt,
                updatedAt: decodedHighlight.updatedAt,
                book: resolvedBook
            )
            : decodedHighlight

        self.init(
            highlight: resolvedHighlight,
            book: resolvedBook,
            matchedTerms: try container.decodeFirstPresent([String].self, keys: ["matched_terms", "terms"]) ?? [],
            snippet: try container.decodeFirstPresent(String.self, keys: ["snippet", "excerpt", "text_preview"]),
            matchedInNote: try container.decodeFirstPresent(Bool.self, keys: ["matched_in_note", "note_match"]),
            matchedField: try container.decodeFirstPresent(String.self, keys: ["matched_field", "field"]),
            matchReason: try container.decodeFirstPresent(String.self, keys: ["match_reason", "reason"]),
            semanticScore: try container.decodeFirstPresent(Double.self, keys: ["semantic_score", "score"])
        )
    }

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

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
