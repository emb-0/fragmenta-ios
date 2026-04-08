import Foundation

struct BookDetail: Codable, Identifiable, Hashable, Sendable {
    struct Stats: Codable, Hashable, Sendable {
        let highlightCount: Int
        let noteCount: Int
        let lastImportedAt: Date?
        let firstHighlightAt: Date?
        let latestHighlightAt: Date?

        init(
            highlightCount: Int,
            noteCount: Int,
            lastImportedAt: Date?,
            firstHighlightAt: Date?,
            latestHighlightAt: Date?
        ) {
            self.highlightCount = highlightCount
            self.noteCount = noteCount
            self.lastImportedAt = lastImportedAt
            self.firstHighlightAt = firstHighlightAt
            self.latestHighlightAt = latestHighlightAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            self.init(
                highlightCount: try container.decodeFirstPresent(Int.self, keys: ["highlight_count", "highlights_count"]) ?? 0,
                noteCount: try container.decodeFirstPresent(Int.self, keys: ["note_count", "notes_count"]) ?? 0,
                lastImportedAt: try container.decodeFirstPresent(Date.self, keys: ["last_imported_at", "updated_at"]),
                firstHighlightAt: try container.decodeFirstPresent(Date.self, keys: ["first_highlight_at", "created_at"]),
                latestHighlightAt: try container.decodeFirstPresent(Date.self, keys: ["latest_highlight_at", "updated_at"])
            )
        }
    }

    let book: Book
    let stats: Stats

    var id: String {
        book.id
    }
}

struct BookMetadataPayload: Codable, Sendable {
    let book: Book
    let stats: BookDetail.Stats?

    init(book: Book, stats: BookDetail.Stats? = nil) {
        self.book = book
        self.stats = stats
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        if let nestedBook = try container.decodeIfPresent(Book.self, forKey: AnyCodingKey("book")) {
            self.init(
                book: nestedBook,
                stats: try container.decodeIfPresent(BookDetail.Stats.self, forKey: AnyCodingKey("stats"))
            )
            return
        }

        self.init(book: try Book(from: decoder))
    }
}
