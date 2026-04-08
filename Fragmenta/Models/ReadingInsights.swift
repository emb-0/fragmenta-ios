import Foundation

struct ReadingInsights: Codable, Hashable, Sendable {
    struct Totals: Codable, Hashable, Sendable {
        let bookCount: Int
        let highlightCount: Int
        let noteCount: Int
        let currentStreakDays: Int?
        let activeDays: Int?
        let averageHighlightsPerWeek: Double?
        let averageNotesPerWeek: Double?
        let paceSummary: String?

        init(
            bookCount: Int,
            highlightCount: Int,
            noteCount: Int,
            currentStreakDays: Int? = nil,
            activeDays: Int? = nil,
            averageHighlightsPerWeek: Double? = nil,
            averageNotesPerWeek: Double? = nil,
            paceSummary: String? = nil
        ) {
            self.bookCount = bookCount
            self.highlightCount = highlightCount
            self.noteCount = noteCount
            self.currentStreakDays = currentStreakDays
            self.activeDays = activeDays
            self.averageHighlightsPerWeek = averageHighlightsPerWeek
            self.averageNotesPerWeek = averageNotesPerWeek
            self.paceSummary = paceSummary
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            self.init(
                bookCount: try container.decodeFirstPresent(Int.self, keys: ["book_count", "books", "books_count"]) ?? 0,
                highlightCount: try container.decodeFirstPresent(Int.self, keys: ["highlight_count", "highlights", "highlights_count"]) ?? 0,
                noteCount: try container.decodeFirstPresent(Int.self, keys: ["note_count", "notes", "notes_count"]) ?? 0,
                currentStreakDays: try container.decodeFirstPresent(Int.self, keys: ["current_streak_days", "streak_days"]),
                activeDays: try container.decodeFirstPresent(Int.self, keys: ["active_days", "active_days_count"]),
                averageHighlightsPerWeek: try container.decodeFirstPresent(Double.self, keys: ["average_highlights_per_week", "avg_highlights_per_week"]),
                averageNotesPerWeek: try container.decodeFirstPresent(Double.self, keys: ["average_notes_per_week", "avg_notes_per_week"]),
                paceSummary: try container.decodeFirstPresent(String.self, keys: ["pace_summary", "activity_summary", "summary"])
            )
        }
    }

    struct ActivityPoint: Codable, Hashable, Identifiable, Sendable {
        let date: Date
        let highlightCount: Int
        let noteCount: Int

        var id: Date { date }

        init(date: Date, highlightCount: Int, noteCount: Int = 0) {
            self.date = date
            self.highlightCount = highlightCount
            self.noteCount = noteCount
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            self.init(
                date: try container.decodeFirstPresent(Date.self, keys: ["date", "day", "bucket", "period_start"])
                    ?? .distantPast,
                highlightCount: try container.decodeFirstPresent(Int.self, keys: ["highlight_count", "highlights", "count"]) ?? 0,
                noteCount: try container.decodeFirstPresent(Int.self, keys: ["note_count", "notes"]) ?? 0
            )
        }
    }

    struct Passage: Codable, Hashable, Identifiable, Sendable {
        let id: String
        let highlight: Highlight
        let book: BookReference?
        let annotationCount: Int?
        let summary: String?

        init(
            id: String,
            highlight: Highlight,
            book: BookReference? = nil,
            annotationCount: Int? = nil,
            summary: String? = nil
        ) {
            self.id = id
            self.highlight = highlight
            self.book = book
            self.annotationCount = annotationCount
            self.summary = summary
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)

            if let nestedHighlight = try container.decodeIfPresent(Highlight.self, forKey: AnyCodingKey("highlight")) {
                self.init(
                    id: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("id")) ?? nestedHighlight.id,
                    highlight: nestedHighlight,
                    book: try container.decodeIfPresent(BookReference.self, forKey: AnyCodingKey("book")) ?? nestedHighlight.book,
                    annotationCount: try container.decodeFirstPresent(Int.self, keys: ["annotation_count", "note_count"]),
                    summary: try container.decodeFirstPresent(String.self, keys: ["summary", "reason"])
                )
                return
            }

            let highlight = Highlight(
                id: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("highlight_id"))
                    ?? container.decode(String.self, forKey: AnyCodingKey("id")),
                bookID: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("book_id")) ?? "",
                text: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("text")) ?? "",
                note: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("note")),
                location: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("location")),
                page: try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("page")),
                chapter: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("chapter")),
                colorName: try container.decodeIfPresent(String.self, forKey: AnyCodingKey("color_name")),
                highlightedAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("highlighted_at")),
                createdAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("created_at")),
                updatedAt: try container.decodeIfPresent(Date.self, forKey: AnyCodingKey("updated_at")),
                book: try container.decodeIfPresent(BookReference.self, forKey: AnyCodingKey("book"))
            )

            self.init(
                id: highlight.id,
                highlight: highlight,
                book: highlight.book,
                annotationCount: try container.decodeFirstPresent(Int.self, keys: ["annotation_count", "note_count"]),
                summary: try container.decodeFirstPresent(String.self, keys: ["summary", "reason"])
            )
        }
    }

    let totals: Totals
    let activity: [ActivityPoint]
    let topAnnotatedBooks: [Book]
    let topAnnotatedPassages: [Passage]
    let generatedAt: Date?

    init(
        totals: Totals,
        activity: [ActivityPoint],
        topAnnotatedBooks: [Book],
        topAnnotatedPassages: [Passage],
        generatedAt: Date? = nil
    ) {
        self.totals = totals
        self.activity = activity.sorted { $0.date < $1.date }
        self.topAnnotatedBooks = topAnnotatedBooks
        self.topAnnotatedPassages = topAnnotatedPassages
        self.generatedAt = generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        let totals = try container.decodeIfPresent(Totals.self, forKey: AnyCodingKey("totals"))
            ?? Totals(
                bookCount: try container.decodeFirstPresent(Int.self, keys: ["book_count", "books", "books_count"]) ?? 0,
                highlightCount: try container.decodeFirstPresent(Int.self, keys: ["highlight_count", "highlights", "highlights_count"]) ?? 0,
                noteCount: try container.decodeFirstPresent(Int.self, keys: ["note_count", "notes", "notes_count"]) ?? 0,
                currentStreakDays: try container.decodeFirstPresent(Int.self, keys: ["current_streak_days", "streak_days"]),
                activeDays: try container.decodeFirstPresent(Int.self, keys: ["active_days", "active_days_count"]),
                averageHighlightsPerWeek: try container.decodeFirstPresent(Double.self, keys: ["average_highlights_per_week", "avg_highlights_per_week"]),
                averageNotesPerWeek: try container.decodeFirstPresent(Double.self, keys: ["average_notes_per_week", "avg_notes_per_week"]),
                paceSummary: try container.decodeFirstPresent(String.self, keys: ["pace_summary", "activity_summary", "summary"])
            )

        let mergedActivity: [ActivityPoint]
        if let unifiedActivity = try container.decodeFirstPresent([ActivityPoint].self, keys: ["activity", "timeline"]) {
            mergedActivity = unifiedActivity
        } else {
            let highlightActivity = try container.decodeFirstPresent([SimpleActivityPoint].self, keys: ["highlight_frequency", "highlight_timeline"]) ?? []
            let noteActivity = try container.decodeFirstPresent([SimpleActivityPoint].self, keys: ["note_activity", "note_timeline"]) ?? []
            mergedActivity = Self.mergeActivity(highlightActivity: highlightActivity, noteActivity: noteActivity)
        }

        self.init(
            totals: totals,
            activity: mergedActivity,
            topAnnotatedBooks: try container.decodeFirstPresent([Book].self, keys: ["top_annotated_books", "top_books", "books"]) ?? [],
            topAnnotatedPassages: try container.decodeFirstPresent([Passage].self, keys: ["most_annotated_passages", "top_passages", "passages"]) ?? [],
            generatedAt: try container.decodeFirstPresent(Date.self, keys: ["generated_at", "updated_at"])
        )
    }

    var isEmpty: Bool {
        totals.bookCount == 0
            && totals.highlightCount == 0
            && totals.noteCount == 0
            && activity.isEmpty
            && topAnnotatedBooks.isEmpty
            && topAnnotatedPassages.isEmpty
    }

    private struct SimpleActivityPoint: Codable, Hashable, Sendable {
        let date: Date
        let count: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            self.date = try container.decodeFirstPresent(Date.self, keys: ["date", "day", "bucket", "period_start"]) ?? .distantPast
            self.count = try container.decodeFirstPresent(Int.self, keys: ["count", "value", "highlights", "notes"]) ?? 0
        }
    }

    private static func mergeActivity(
        highlightActivity: [SimpleActivityPoint],
        noteActivity: [SimpleActivityPoint]
    ) -> [ActivityPoint] {
        var merged: [Date: ActivityPoint] = [:]

        for point in highlightActivity {
            merged[point.date] = ActivityPoint(date: point.date, highlightCount: point.count, noteCount: merged[point.date]?.noteCount ?? 0)
        }

        for point in noteActivity {
            let existing = merged[point.date]
            merged[point.date] = ActivityPoint(
                date: point.date,
                highlightCount: existing?.highlightCount ?? 0,
                noteCount: point.count
            )
        }

        return merged.values.sorted { $0.date < $1.date }
    }
}
