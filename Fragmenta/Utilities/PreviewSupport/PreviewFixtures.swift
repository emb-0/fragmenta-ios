import Foundation

#if DEBUG
enum PreviewFixtures {
    static let books: [Book] = [
        Book(
            id: "bk_mary_oliver",
            title: "Devotions",
            author: "Mary Oliver",
            source: .kindleExport,
            highlightCount: 84,
            coverURL: nil,
            synopsis: "A collected shelf of poems and the kind of sentences that stay with you after the page closes.",
            lastImportedAt: Date().addingTimeInterval(-86_400 * 4),
            createdAt: Date().addingTimeInterval(-86_400 * 120),
            updatedAt: Date().addingTimeInterval(-86_400 * 2)
        ),
        Book(
            id: "bk_annie_dillard",
            title: "Pilgrim at Tinker Creek",
            author: "Annie Dillard",
            source: .kindleExport,
            highlightCount: 43,
            coverURL: nil,
            synopsis: "Field notes, devotion, and attention rendered with enough texture to make every highlight feel tactile.",
            lastImportedAt: Date().addingTimeInterval(-86_400 * 10),
            createdAt: Date().addingTimeInterval(-86_400 * 180),
            updatedAt: Date().addingTimeInterval(-86_400 * 9)
        )
    ]

    static let highlights: [Highlight] = [
        Highlight(
            id: "hl_001",
            bookID: books[0].id,
            text: "Instructions for living a life: Pay attention. Be astonished. Tell about it.",
            note: "This is the tone Fragmenta should carry everywhere.",
            location: 418,
            page: nil,
            chapter: "Instructions",
            colorName: nil,
            highlightedAt: Date().addingTimeInterval(-86_400 * 12),
            createdAt: Date().addingTimeInterval(-86_400 * 12),
            book: BookReference(id: books[0].id, title: books[0].title, author: books[0].author)
        ),
        Highlight(
            id: "hl_002",
            bookID: books[0].id,
            text: "Whoever you are, no matter how lonely, the world offers itself to your imagination.",
            note: nil,
            location: 511,
            page: nil,
            chapter: "Wild Geese",
            colorName: nil,
            highlightedAt: Date().addingTimeInterval(-86_400 * 8),
            createdAt: Date().addingTimeInterval(-86_400 * 8),
            book: BookReference(id: books[0].id, title: books[0].title, author: books[0].author)
        )
    ]

    static let bookDetail = BookDetail(
        book: books[0],
        highlights: highlights,
        stats: BookDetail.Stats(
            highlightCount: highlights.count,
            noteCount: 1,
            lastImportedAt: books[0].lastImportedAt
        )
    )

    static let searchResults: [HighlightSearchResult] = [
        HighlightSearchResult(
            highlight: highlights[0],
            book: BookReference(id: books[0].id, title: books[0].title, author: books[0].author),
            matchedTerms: ["attention", "astonished"]
        )
    ]

    static let importResponse = ImportResponse(
        importID: "imp_preview",
        status: .completed,
        booksCreated: 1,
        booksUpdated: 0,
        highlightsImported: 32,
        duplicateHighlights: 0,
        warnings: [],
        message: "Preview import completed successfully."
    )
}
#endif
