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
            noteCount: 18,
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
            noteCount: 6,
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
            updatedAt: Date().addingTimeInterval(-86_400 * 10),
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
            updatedAt: Date().addingTimeInterval(-86_400 * 7),
            book: BookReference(id: books[0].id, title: books[0].title, author: books[0].author)
        )
    ]

    static let bookDetail = BookDetail(
        book: books[0],
        stats: BookDetail.Stats(
            highlightCount: highlights.count,
            noteCount: 1,
            lastImportedAt: books[0].lastImportedAt,
            firstHighlightAt: Date().addingTimeInterval(-86_400 * 80),
            latestHighlightAt: Date().addingTimeInterval(-86_400 * 7)
        )
    )

    static let highlightPage = PaginatedResponse(
        items: highlights,
        pageInfo: PageInfo(page: 1, limit: 24, total: 40, hasMore: true, nextPage: 2)
    )

    static let searchResults: [HighlightSearchResult] = [
        HighlightSearchResult(
            highlight: highlights[0],
            book: BookReference(id: books[0].id, title: books[0].title, author: books[0].author),
            matchedTerms: ["attention", "astonished"],
            snippet: "Instructions for living a life: Pay attention. Be astonished. Tell about it.",
            matchedInNote: true,
            matchedField: "note"
        )
    ]

    static let searchPage = PaginatedResponse(
        items: searchResults,
        pageInfo: PageInfo(page: 1, limit: 20, total: 1, hasMore: false, nextPage: nil)
    )

    static let importPreview = ImportPreview(
        summary: ImportSummary(
            booksDetected: 2,
            highlightsDetected: 32,
            notesDetected: 7,
            duplicatesDetected: 1,
            warningsCount: 1,
            warnings: ["One duplicate highlight was ignored."]
        ),
        detectedBooks: [
            ImportPreview.DetectedBook(
                id: "preview_devotions",
                title: "Devotions",
                author: "Mary Oliver",
                highlightsDetected: 18,
                notesDetected: 5
            ),
            ImportPreview.DetectedBook(
                id: "preview_tinker",
                title: "Pilgrim at Tinker Creek",
                author: "Annie Dillard",
                highlightsDetected: 14,
                notesDetected: 2
            )
        ],
        message: "Preview completed."
    )

    static let importResponse = ImportResponse(
        importID: "imp_preview",
        status: .completed,
        summary: importPreview.summary,
        booksCreated: 1,
        booksUpdated: 1,
        createdAt: Date().addingTimeInterval(-120),
        completedAt: Date().addingTimeInterval(-60),
        filename: "My Clippings.txt",
        message: "Preview import completed successfully."
    )

    static let importRecords: [ImportRecord] = [
        ImportRecord(
            id: "imp_preview",
            status: .completed,
            summary: importPreview.summary,
            booksCreated: 1,
            booksUpdated: 1,
            filename: "My Clippings.txt",
            source: "kindle_txt",
            createdAt: Date().addingTimeInterval(-3_600),
            completedAt: Date().addingTimeInterval(-3_500),
            message: "Import completed."
        )
    ]

    static let exportArtifact = ExportArtifact(
        format: .markdown,
        fileURL: URL(fileURLWithPath: "/tmp/fragmenta-preview.md"),
        generatedAt: Date(),
        byteCount: 4_096
    )
}
#endif
