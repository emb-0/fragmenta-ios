import Foundation

struct ImportSummary: Codable, Hashable, Sendable {
    let booksDetected: Int
    let highlightsDetected: Int
    let notesDetected: Int
    let duplicatesDetected: Int
    let warningsCount: Int?
    let warnings: [String]

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

        self.importID = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("import_id"))
            ?? container.decode(String.self, forKey: AnyCodingKey("id"))
        self.status = try container.decode(Status.self, forKey: AnyCodingKey("status"))
        self.booksCreated = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_created")) ?? 0
        self.booksUpdated = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_updated")) ?? 0
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at"))
        self.completedAt = try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("completed_at"))
        self.filename = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("filename"))
        self.message = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("message"))

        if let nestedSummary = try container.decodeIfPresent(ImportSummary.self, forKey: AnyCodingKey("summary")) {
            self.summary = nestedSummary
        } else {
            self.summary = ImportSummary(
                booksDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_detected")) ?? booksCreated + booksUpdated,
                highlightsDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("highlights_imported")) ?? 0,
                notesDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("notes_detected")) ?? 0,
                duplicatesDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("duplicate_highlights")) ?? 0,
                warningsCount: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("warnings_count")),
                warnings: try container.decodeIfPresent([String].self, forKey: AnyCodingKey("warnings")) ?? []
            )
        }
    }
}
