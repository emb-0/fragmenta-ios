import Foundation

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
        var lines = ["“\(text.trimmed)”"]

        if let note, note.isBlank == false {
            lines.append("")
            lines.append("Note: \(note)")
        }

        if let locationLabel {
            lines.append("")
            lines.append(locationLabel)
        }

        return lines.joined(separator: "\n")
    }
}
