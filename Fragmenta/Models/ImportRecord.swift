import Foundation

struct ImportRecord: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let status: ImportResponse.Status
    let summary: ImportSummary
    let booksCreated: Int?
    let booksUpdated: Int?
    let filename: String?
    let source: String?
    let createdAt: Date?
    let completedAt: Date?
    let message: String?

    var summaryLine: String {
        "\(summary.highlightsDetected) highlights, \(summary.booksDetected) books"
    }

    init(
        id: String,
        status: ImportResponse.Status,
        summary: ImportSummary,
        booksCreated: Int?,
        booksUpdated: Int?,
        filename: String?,
        source: String?,
        createdAt: Date?,
        completedAt: Date?,
        message: String?
    ) {
        self.id = id
        self.status = status
        self.summary = summary
        self.booksCreated = booksCreated
        self.booksUpdated = booksUpdated
        self.filename = filename
        self.source = source
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        self.id = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id"))
            ?? container.decode(String.self, forKey: AnyCodingKey("import_id"))
        self.status = try container.decode(ImportResponse.Status.self, forKey: AnyCodingKey("status"))
        self.booksCreated = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_created"))
        self.booksUpdated = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_updated"))
        self.filename = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("filename"))
        self.source = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("source"))
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at"))
        self.completedAt = try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("completed_at"))
        self.message = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("message"))

        if let nestedSummary = try container.decodeIfPresent(ImportSummary.self, forKey: AnyCodingKey("summary")) {
            self.summary = nestedSummary
        } else {
            self.summary = ImportSummary(
                booksDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_detected")) ?? ((booksCreated ?? 0) + (booksUpdated ?? 0)),
                highlightsDetected: try container.decodeFirstPresent(Int.self, keys: ["highlights_detected", "highlights_imported"]) ?? 0,
                notesDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("notes_detected")) ?? 0,
                duplicatesDetected: try container.decodeFirstPresent(Int.self, keys: ["duplicates_detected", "duplicate_highlights"]) ?? 0,
                warningsCount: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("warnings_count")),
                warnings: try container.decodeIfPresent([String].self, forKey: AnyCodingKey("warnings")) ?? []
            )
        }
    }
}
