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
}
