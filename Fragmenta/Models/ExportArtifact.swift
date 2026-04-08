import Foundation

enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case markdown
    case csv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .markdown:
            return "Markdown"
        case .csv:
            return "CSV"
        }
    }

    var path: String {
        switch self {
        case .markdown:
            return "/api/exports/markdown"
        case .csv:
            return "/api/exports/csv"
        }
    }

    var fileExtension: String {
        switch self {
        case .markdown:
            return "md"
        case .csv:
            return "csv"
        }
    }
}

enum ExportScope: Hashable, Sendable {
    case library
    case book(bookID: String)

    var queryItems: [URLQueryItem] {
        switch self {
        case .library:
            return []
        case .book(let bookID):
            return [URLQueryItem(name: "book_id", value: bookID)]
        }
    }
}

struct ExportArtifact: Hashable, Sendable {
    let format: ExportFormat
    let scope: ExportScope
    let fileURL: URL
    let generatedAt: Date
    let byteCount: Int
}
