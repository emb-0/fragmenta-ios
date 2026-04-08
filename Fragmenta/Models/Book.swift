import Foundation

struct Book: Codable, Identifiable, Hashable, Sendable {
    enum Source: String, Codable, CaseIterable, Sendable {
        case kindleExport = "kindle_export"
        case manualImport = "manual_import"
        case unknown

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            self = Source(rawValue: rawValue) ?? .unknown
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    let id: String
    let title: String
    let author: String?
    let source: Source
    let highlightCount: Int
    let noteCount: Int?
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

    var noteCountLabel: String? {
        guard let noteCount else {
            return nil
        }

        return noteCount == 1 ? "1 note" : "\(noteCount) notes"
    }

    var isRecentlyImported: Bool {
        guard let lastImportedAt else {
            return false
        }

        return lastImportedAt > Date().addingTimeInterval(-86_400 * 10)
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
