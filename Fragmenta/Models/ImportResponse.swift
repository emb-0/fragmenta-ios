import Foundation

struct ImportResponse: Codable, Hashable, Sendable {
    enum Status: String, Codable, Sendable {
        case accepted
        case processing
        case completed
        case failed
    }

    let importID: String
    let status: Status
    let booksCreated: Int
    let booksUpdated: Int
    let highlightsImported: Int
    let duplicateHighlights: Int
    let warnings: [String]
    let message: String?

    var summaryLine: String {
        "\(highlightsImported) highlights, \(booksCreated + booksUpdated) books"
    }
}
