import Foundation

struct Collection: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String?
    let tags: [String]
    let bookCount: Int
    let highlightCount: Int?
    let noteCount: Int?
    let containsBook: Bool?
    let previewBooks: [Book]
    let createdAt: Date?
    let updatedAt: Date?

    init(
        id: String,
        title: String,
        summary: String? = nil,
        tags: [String] = [],
        bookCount: Int = 0,
        highlightCount: Int? = nil,
        noteCount: Int? = nil,
        containsBook: Bool? = nil,
        previewBooks: [Book] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary?.trimmed.nilIfBlank
        self.tags = tags
            .map(\.trimmed)
            .filter { $0.isBlank == false }
        self.bookCount = bookCount
        self.highlightCount = highlightCount
        self.noteCount = noteCount
        self.containsBook = containsBook
        self.previewBooks = previewBooks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.init(
            id: try container.decode(String.self, forKey: AnyCodingKey("id")),
            title: try container.decodeFirstPresent(String.self, keys: ["title", "name"]) ?? "Untitled Collection",
            summary: try container.decodeFirstPresent(String.self, keys: ["summary", "description", "note"]),
            tags: try Collection.decodeTags(from: container),
            bookCount: try container.decodeFirstPresent(Int.self, keys: ["book_count", "books_count"]) ?? 0,
            highlightCount: try container.decodeFirstPresent(Int.self, keys: ["highlight_count", "highlights_count"]),
            noteCount: try container.decodeFirstPresent(Int.self, keys: ["note_count", "notes_count"]),
            containsBook: try container.decodeFirstPresent(Bool.self, keys: ["contains_book", "is_member", "included"]),
            previewBooks: try container.decodeFirstPresent([Book].self, keys: ["preview_books", "books_preview", "books"]) ?? [],
            createdAt: try container.decodeFirstPresent(Date.self, keys: ["created_at"]),
            updatedAt: try container.decodeFirstPresent(Date.self, keys: ["updated_at"])
        )
    }

    var subtitleLine: String {
        if let summary, summary.isBlank == false {
            return summary
        }

        if tags.isEmpty == false {
            return tags.prefix(3).joined(separator: " · ")
        }

        return bookCount == 1 ? "1 book" : "\(bookCount) books"
    }

    fileprivate static func decodeTags(from container: KeyedDecodingContainer<AnyCodingKey>) throws -> [String] {
        if let rawTags = try container.decodeFirstPresent([String].self, keys: ["tags", "tag_names", "labels"]) {
            return rawTags
        }

        if let tagObjects = try container.decodeFirstPresent([Tag].self, keys: ["tags", "labels"]) {
            return tagObjects.map(\.title)
        }

        return []
    }

    fileprivate struct Tag: Codable, Hashable, Sendable {
        let title: String

        init(from decoder: Decoder) throws {
            if let singleValue = try? decoder.singleValueContainer(), let stringValue = try? singleValue.decode(String.self) {
                self.title = stringValue
                return
            }

            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            self.title = try container.decodeFirstPresent(String.self, keys: ["title", "name", "label"]) ?? ""
        }
    }
}

struct CollectionDetail: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String?
    let tags: [String]
    let books: [Book]
    let bookCount: Int
    let highlightCount: Int?
    let noteCount: Int?
    let createdAt: Date?
    let updatedAt: Date?

    init(
        id: String,
        title: String,
        summary: String? = nil,
        tags: [String] = [],
        books: [Book] = [],
        bookCount: Int = 0,
        highlightCount: Int? = nil,
        noteCount: Int? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary?.trimmed.nilIfBlank
        self.tags = tags
        self.books = books
        self.bookCount = bookCount
        self.highlightCount = highlightCount
        self.noteCount = noteCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        if let nestedCollection = try container.decodeIfPresent(Collection.self, forKey: AnyCodingKey("collection")) {
            self.init(
                id: nestedCollection.id,
                title: nestedCollection.title,
                summary: nestedCollection.summary,
                tags: nestedCollection.tags,
                books: try container.decodeFirstPresent([Book].self, keys: ["books", "items"]) ?? nestedCollection.previewBooks,
                bookCount: nestedCollection.bookCount == 0 ? ((try container.decodeFirstPresent([Book].self, keys: ["books", "items"]) ?? []).count) : nestedCollection.bookCount,
                highlightCount: nestedCollection.highlightCount,
                noteCount: nestedCollection.noteCount,
                createdAt: nestedCollection.createdAt,
                updatedAt: nestedCollection.updatedAt
            )
            return
        }

        let books = try container.decodeFirstPresent([Book].self, keys: ["books", "items"]) ?? []
        self.init(
            id: try container.decode(String.self, forKey: AnyCodingKey("id")),
            title: try container.decodeFirstPresent(String.self, keys: ["title", "name"]) ?? "Untitled Collection",
            summary: try container.decodeFirstPresent(String.self, keys: ["summary", "description", "note"]),
            tags: try Collection.decodeTags(from: container),
            books: books,
            bookCount: try container.decodeFirstPresent(Int.self, keys: ["book_count", "books_count"]) ?? books.count,
            highlightCount: try container.decodeFirstPresent(Int.self, keys: ["highlight_count", "highlights_count"]),
            noteCount: try container.decodeFirstPresent(Int.self, keys: ["note_count", "notes_count"]),
            createdAt: try container.decodeFirstPresent(Date.self, keys: ["created_at"]),
            updatedAt: try container.decodeFirstPresent(Date.self, keys: ["updated_at"])
        )
    }

    var collection: Collection {
        Collection(
            id: id,
            title: title,
            summary: summary,
            tags: tags,
            bookCount: bookCount,
            highlightCount: highlightCount,
            noteCount: noteCount,
            containsBook: nil,
            previewBooks: Array(books.prefix(3)),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
