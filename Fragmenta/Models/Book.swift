import Foundation

struct Book: Codable, Identifiable, Hashable, Sendable {
    enum Source: String, Codable, CaseIterable, Sendable {
        case kindleExport = "kindle_export"
        case manualImport = "manual_import"
        case unknown
    }

    let id: String
    let title: String
    let author: String?
    let source: Source
    let highlightCount: Int
    let coverURL: URL?
    let synopsis: String?
    let lastImportedAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    var displayAuthor: String {
        let trimmedAuthor = author?.trimmed ?? ""
        return trimmedAuthor.isEmpty ? "Unknown author" : trimmedAuthor
    }

    var highlightCountLabel: String {
        highlightCount == 1 ? "1 highlight" : "\(highlightCount) highlights"
    }
}

struct BookReference: Codable, Hashable, Sendable {
    let id: String
    let title: String
    let author: String?

    var displayAuthor: String {
        let trimmedAuthor = author?.trimmed ?? ""
        return trimmedAuthor.isEmpty ? "Unknown author" : trimmedAuthor
    }
}
