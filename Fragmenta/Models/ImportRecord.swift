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
        let rawStatus = try container.decodeFirstPresent(String.self, keys: ["status", "parse_status"])

        self.id = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id"))
            ?? container.decode(String.self, forKey: AnyCodingKey("import_id"))
        self.status = Self.resolvedStatus(from: rawStatus)
        self.booksCreated = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_created"))
        self.booksUpdated = try container.decodeFirstPresent(Int.self, keys: ["books_updated", "books_existing"])
        self.filename = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("filename"))
        self.source = try container.decodeFirstPresent(String.self, keys: ["source", "source_type"])
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at"))
        self.completedAt = try container.decodeFirstPresent(Date.self, keys: ["completed_at", "updated_at"])
        self.message = try container.decodeFirstPresent(String.self, keys: ["message", "error_message"])

        if let nestedSummary = try container.decodeFirstPresent(ImportSummary.self, keys: ["summary", "import_summary"]) {
            self.summary = nestedSummary
        } else {
            self.summary = ImportSummary(
                booksDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_detected")) ?? ((booksCreated ?? 0) + (booksUpdated ?? 0)),
                highlightsDetected: try container.decodeFirstPresent(Int.self, keys: ["highlights_detected", "highlights_imported"]) ?? 0,
                notesDetected: try container.decodeFirstPresent(Int.self, keys: ["notes_detected", "notes_found"]) ?? 0,
                duplicatesDetected: try container.decodeFirstPresent(Int.self, keys: ["duplicates_detected", "duplicate_highlights"]) ?? 0,
                warningsCount: try container.decodeFirstPresent(Int.self, keys: ["warnings_count", "parse_warnings_count"]),
                warnings: try container.decodeIfPresent([String].self, forKey: AnyCodingKey("warnings")) ?? []
            )
        }
    }

    private static func resolvedStatus(from rawValue: String?) -> ImportResponse.Status {
        guard let rawValue else {
            return .completed
        }

        switch rawValue.lowercased() {
        case "accepted", "queued":
            return .accepted
        case "processing", "pending", "running":
            return .processing
        case "completed", "complete", "succeeded", "success":
            return .completed
        case "failed", "failure", "error":
            return .failed
        default:
            return .completed
        }
    }
}
