import Foundation

struct HighlightCitation: Hashable, Sendable {
    let bookTitle: String
    let author: String?
    let chapter: String?
    let locationLabel: String?

    init(
        bookTitle: String,
        author: String?,
        chapter: String? = nil,
        locationLabel: String? = nil
    ) {
        self.bookTitle = bookTitle
        self.author = author
        self.chapter = chapter
        self.locationLabel = locationLabel
    }

    var line: String {
        var parts = [bookTitle]

        if let author, author.isBlank == false {
            parts.append(author)
        }

        if let chapter, chapter.isBlank == false {
            parts.append(chapter)
        }

        if let locationLabel, locationLabel.isBlank == false {
            parts.append(locationLabel)
        }

        return parts.joined(separator: " · ")
    }
}

struct Highlight: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let bookID: String
    let text: String
    let note: String?
    let location: Int?
    let page: Int?
    let chapter: String?
    let colorName: String?
    let highlightedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
    let book: BookReference?

    init(
        id: String,
        bookID: String,
        text: String,
        note: String?,
        location: Int?,
        page: Int?,
        chapter: String?,
        colorName: String?,
        highlightedAt: Date?,
        createdAt: Date?,
        updatedAt: Date?,
        book: BookReference?
    ) {
        self.id = id
        self.bookID = bookID
        self.text = text
        self.note = note?.trimmed.nilIfBlank
        self.location = location
        self.page = page
        self.chapter = chapter?.trimmed.nilIfBlank
        self.colorName = colorName?.trimmed.nilIfBlank
        self.highlightedAt = highlightedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.book = book
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let sourceLocation = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("source_location"))

        self.init(
            id: try container.decode(String.self, forKey: AnyCodingKey("id")),
            bookID: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("book_id")) ?? "",
            text: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("text")) ?? "",
            note: try container.decodeFirstPresent(String.self, keys: ["note", "note_text"]),
            location: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("location")) ?? Self.locationValue(from: sourceLocation),
            page: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("page")) ?? Self.pageValue(from: sourceLocation),
            chapter: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("chapter")),
            colorName: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("color_name")),
            highlightedAt: try container.decodeFirstPresent(Date.self, keys: ["highlighted_at", "created_at"]),
            createdAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at")),
            updatedAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("updated_at")),
            book: try container.decodeIfPresent(BookReference.self, forKey: AnyCodingKey("book"))
        )
    }

    var locationLabel: String? {
        if let page {
            return "Page \(page)"
        }

        if let location {
            return "Location \(location)"
        }

        return nil
    }

    var shareBody: String {
        formattedBody()
    }

    func shareBody(citation: HighlightCitation?) -> String {
        formattedBody(includeCitation: true, citation: citation)
    }

    func copyBodyWithCitation(citation: HighlightCitation?) -> String {
        formattedBody(includeCitation: true, citation: citation)
    }

    private func formattedBody(
        includeCitation: Bool = false,
        citation: HighlightCitation? = nil
    ) -> String {
        var lines = ["“\(text.trimmed)”"]

        if let note, note.isBlank == false {
            lines.append("")
            lines.append("Note: \(note)")
        }

        if includeCitation, let citation, citation.line.isBlank == false {
            lines.append("")
            lines.append("— \(citation.line)")
        } else if let locationLabel {
            lines.append("")
            lines.append(locationLabel)
        }

        return lines.joined(separator: "\n")
    }

    private static func pageValue(from rawSourceLocation: String?) -> Int? {
        guard let rawSourceLocation else {
            return nil
        }

        let lowercase = rawSourceLocation.lowercased()
        guard lowercase.contains("page") else {
            return nil
        }

        return numericValue(in: lowercase)
    }

    private static func locationValue(from rawSourceLocation: String?) -> Int? {
        guard let rawSourceLocation else {
            return nil
        }

        let lowercase = rawSourceLocation.lowercased()
        guard lowercase.contains("loc") || lowercase.contains("location") || lowercase.allSatisfy({ $0.isNumber || $0.isWhitespace }) else {
            return nil
        }

        return numericValue(in: lowercase)
    }

    private static func numericValue(in text: String) -> Int? {
        let digits = text.filter(\.isNumber)
        return Int(digits)
    }
}

private extension String {
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
}
