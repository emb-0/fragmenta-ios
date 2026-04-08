import Foundation

struct BookSummaryPayload: Codable, Hashable, Sendable {
    let summary: String?
    let themes: [BookDiscovery.Theme]
    let updatedAt: Date?

    init(summary: String? = nil, themes: [BookDiscovery.Theme] = [], updatedAt: Date? = nil) {
        self.summary = summary?.trimmed.nilIfBlank
        self.themes = themes
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.init(
            summary: try container.decodeFirstPresent(String.self, keys: ["summary", "book_summary", "overview"]),
            themes: try container.decodeFirstPresent([BookDiscovery.Theme].self, keys: ["themes", "thematic_connections", "connections"]) ?? [],
            updatedAt: try container.decodeFirstPresent(Date.self, keys: ["updated_at", "generated_at"])
        )
    }
}

struct BookDiscovery: Hashable, Sendable {
    struct Theme: Codable, Hashable, Identifiable, Sendable {
        let id: String
        let title: String
        let note: String?

        init(id: String? = nil, title: String, note: String? = nil) {
            self.id = id ?? title.lowercased().replacingOccurrences(of: " ", with: "-")
            self.title = title
            self.note = note?.trimmed.nilIfBlank
        }

        init(from decoder: Decoder) throws {
            if let singleValue = try? decoder.singleValueContainer(), let stringValue = try? singleValue.decode(String.self) {
                self.init(title: stringValue)
                return
            }

            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            self.init(
                id: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id")),
                title: try container.decodeFirstPresent(String.self, keys: ["title", "name", "label"]) ?? "",
                note: try container.decodeFirstPresent(String.self, keys: ["note", "summary", "description"])
            )
        }
    }

    struct RelatedHighlight: Codable, Hashable, Identifiable, Sendable {
        let id: String
        let highlight: Highlight
        let book: BookReference?
        let reason: String?
        let score: Double?

        init(
            id: String? = nil,
            highlight: Highlight,
            book: BookReference? = nil,
            reason: String? = nil,
            score: Double? = nil
        ) {
            self.id = id ?? highlight.id
            self.highlight = highlight
            self.book = book ?? highlight.book
            self.reason = reason?.trimmed.nilIfBlank
            self.score = score
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)

            if let nestedHighlight = try container.decodeIfPresent(Highlight.self, forKey: AnyCodingKey("highlight")) {
                self.init(
                    id: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id")),
                    highlight: nestedHighlight,
                    book: try container.decodeIfPresent(BookReference.self, forKey: AnyCodingKey("book")) ?? nestedHighlight.book,
                    reason: try container.decodeFirstPresent(String.self, keys: ["reason", "summary", "connection"]),
                    score: try container.decodeFirstPresent(Double.self, keys: ["score", "semantic_score"])
                )
                return
            }

            let highlight = Highlight(
                id: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("highlight_id"))
                    ?? container.decode(String.self, forKey: AnyCodingKey("id")),
                bookID: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("book_id")) ?? "",
                text: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("text")) ?? "",
                note: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("note")),
                location: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("location")),
                page: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("page")),
                chapter: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("chapter")),
                colorName: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("color_name")),
                highlightedAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("highlighted_at")),
                createdAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at")),
                updatedAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("updated_at")),
                book: try container.decodeIfPresent(BookReference.self, forKey: AnyCodingKey("book"))
            )

            self.init(
                id: highlight.id,
                highlight: highlight,
                book: highlight.book,
                reason: try container.decodeFirstPresent(String.self, keys: ["reason", "summary", "connection"]),
                score: try container.decodeFirstPresent(Double.self, keys: ["score", "semantic_score"])
            )
        }
    }

    let summary: String?
    let themes: [Theme]
    let relatedHighlights: [RelatedHighlight]
    let updatedAt: Date?

    var isEmpty: Bool {
        summary?.isBlank != false && themes.isEmpty && relatedHighlights.isEmpty
    }
}

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
