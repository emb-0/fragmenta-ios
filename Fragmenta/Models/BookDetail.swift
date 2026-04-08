import Foundation

struct BookDetail: Codable, Identifiable, Hashable, Sendable {
    struct Stats: Codable, Hashable, Sendable {
        let highlightCount: Int
        let noteCount: Int
        let lastImportedAt: Date?
        let firstHighlightAt: Date?
        let latestHighlightAt: Date?
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
}
