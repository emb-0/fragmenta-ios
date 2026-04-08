import Foundation

struct ImportSummary: Codable, Hashable, Sendable {
    let booksDetected: Int
    let highlightsDetected: Int
    let notesDetected: Int
    let duplicatesDetected: Int
    let warningsCount: Int?
    let warnings: [String]

    init(
        booksDetected: Int,
        highlightsDetected: Int,
        notesDetected: Int,
        duplicatesDetected: Int,
        warningsCount: Int?,
        warnings: [String]
    ) {
        self.booksDetected = booksDetected
        self.highlightsDetected = highlightsDetected
        self.notesDetected = notesDetected
        self.duplicatesDetected = duplicatesDetected
        self.warningsCount = warningsCount
        self.warnings = warnings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let booksDetected = try container.decodeFirstPresent(Int.self, keys: ["books_detected", "books_found"])
        let booksCreated = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_created")) ?? 0
        let booksExisting = try container.decodeFirstPresent(Int.self, keys: ["books_updated", "books_existing"]) ?? 0

        self.init(
            booksDetected: booksDetected ?? (booksCreated + booksExisting),
            highlightsDetected: try container.decodeFirstPresent(Int.self, keys: ["highlights_detected", "highlights_found", "highlights_imported", "highlights_created"]) ?? 0,
            notesDetected: try container.decodeFirstPresent(Int.self, keys: ["notes_detected", "notes_found"]) ?? 0,
            duplicatesDetected: try container.decodeFirstPresent(Int.self, keys: ["duplicates_detected", "duplicate_highlights", "highlights_skipped_duplicate"]) ?? 0,
            warningsCount: try container.decodeFirstPresent(Int.self, keys: ["warnings_count", "parse_warnings_count"]),
            warnings: try container.decodeIfPresent([String].self, forKey: AnyCodingKey("warnings")) ?? []
        )
    }

    var resolvedWarningsCount: Int {
        warningsCount ?? warnings.count
    }
}

struct ImportResponse: Codable, Hashable, Sendable {
    enum Status: String, Codable, Sendable {
        case accepted
        case processing
        case completed
        case failed

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self).lowercased()

            switch rawValue {
            case "accepted", "queued":
                self = .accepted
            case "processing", "pending", "running":
                self = .processing
            case "completed", "complete", "succeeded", "success":
                self = .completed
            case "failed", "failure", "error":
                self = .failed
            default:
                self = .processing
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
    }

    let importID: String
    let status: Status
    let summary: ImportSummary
    let booksCreated: Int
    let booksUpdated: Int
    let createdAt: Date?
    let completedAt: Date?
    let filename: String?
    let message: String?

    var summaryLine: String {
        "\(summary.highlightsDetected) highlights, \(summary.booksDetected) books"
    }

    init(
        importID: String,
        status: Status,
        summary: ImportSummary,
        booksCreated: Int,
        booksUpdated: Int,
        createdAt: Date?,
        completedAt: Date?,
        filename: String?,
        message: String?
    ) {
        self.importID = importID
        self.status = status
        self.summary = summary
        self.booksCreated = booksCreated
        self.booksUpdated = booksUpdated
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.filename = filename
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        let rawStatus = try container.decodeFirstPresent(String.self, keys: ["status", "parse_status"])

        self.importID = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("import_id"))
            ?? container.decode(String.self, forKey: AnyCodingKey("id"))
        self.status = Self.resolvedStatus(from: rawStatus)
        self.booksCreated = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_created")) ?? 0
        self.booksUpdated = try container.decodeFirstPresent(Int.self, keys: ["books_updated", "books_existing"]) ?? 0
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at"))
        self.completedAt = try container.decodeFirstPresent(Date.self, keys: ["completed_at", "updated_at"])
        self.filename = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("filename"))
        self.message = try container.decodeFirstPresent(String.self, keys: ["message", "error_message"])

        if let nestedSummary = try container.decodeFirstPresent(ImportSummary.self, keys: ["summary", "import_summary"]) {
            self.summary = nestedSummary
        } else {
            self.summary = ImportSummary(
                booksDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_detected")) ?? booksCreated + booksUpdated,
                highlightsDetected: try container.decodeFirstPresent(Int.self, keys: ["highlights_detected", "highlights_imported", "highlights_found"]) ?? 0,
                notesDetected: try container.decodeFirstPresent(Int.self, keys: ["notes_detected", "notes_found"]) ?? 0,
                duplicatesDetected: try container.decodeFirstPresent(Int.self, keys: ["duplicate_highlights", "duplicates_detected", "highlights_skipped_duplicate"]) ?? 0,
                warningsCount: try container.decodeFirstPresent(Int.self, keys: ["warnings_count", "parse_warnings_count"]),
                warnings: try container.decodeIfPresent([String].self, forKey: AnyCodingKey("warnings")) ?? []
            )
        }
    }

    private static func resolvedStatus(from rawValue: String?) -> Status {
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
