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
}
