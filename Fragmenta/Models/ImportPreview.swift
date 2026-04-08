import Foundation

struct ImportPreview: Codable, Hashable, Sendable {
    struct DetectedBook: Codable, Identifiable, Hashable, Sendable {
        let id: String
        let title: String
        let author: String?
        let highlightsDetected: Int
        let notesDetected: Int
    }

    let summary: ImportSummary
    let detectedBooks: [DetectedBook]
    let message: String?

    init(
        summary: ImportSummary,
        detectedBooks: [DetectedBook],
        message: String?
    ) {
        self.summary = summary
        self.detectedBooks = detectedBooks
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        self.message = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("message"))
        self.detectedBooks = try container.decodeFirstPresent([DetectedBook].self, keys: ["detected_books", "books"]) ?? []

        if let nestedSummary = try container.decodeIfPresent(ImportSummary.self, forKey: AnyCodingKey("summary")) {
            self.summary = nestedSummary
        } else {
            self.summary = ImportSummary(
                booksDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("books_detected")) ?? detectedBooks.count,
                highlightsDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("highlights_detected")) ?? 0,
                notesDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("notes_detected")) ?? 0,
                duplicatesDetected: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("duplicates_detected")) ?? 0,
                warningsCount: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("warnings_count")),
                warnings: try container.decodeIfPresent([String].self, forKey: AnyCodingKey("warnings")) ?? []
            )
        }
    }
}
