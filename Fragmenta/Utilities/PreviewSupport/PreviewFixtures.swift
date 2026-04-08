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
            cover: BookCover(
                thumbnailURL: URL(string: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=480&q=80"),
                mediumURL: URL(string: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=900&q=80"),
                largeURL: URL(string: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=1400&q=80"),
                backgroundHex: "6E5944",
                foregroundHex: "F4EEE7",
                width: 640,
                height: 960,
                source: "backend_enrichment"
            ),
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
            cover: BookCover(
                thumbnailURL: URL(string: "https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=480&q=80"),
                mediumURL: URL(string: "https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=900&q=80"),
                largeURL: URL(string: "https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1400&q=80"),
                backgroundHex: "3B4C62",
                foregroundHex: "EFF3F7",
                width: 640,
                height: 960,
                source: "backend_enrichment"
            ),
            synopsis: "Field notes, devotion, and attention rendered with enough texture to make every highlight feel tactile.",
            lastImportedAt: Date().addingTimeInterval(-86_400 * 10),
            createdAt: Date().addingTimeInterval(-86_400 * 180),
            updatedAt: Date().addingTimeInterval(-86_400 * 9)
        ),
        Book(
            id: "bk_ross_gay",
            title: "The Book of Delights",
            author: "Ross Gay",
            source: .manualImport,
            highlightCount: 29,
            noteCount: 12,
            cover: BookCover(
                backgroundHex: "6D8AA8",
                foregroundHex: "F3F5F8",
                width: 640,
                height: 960,
                source: "backend_enrichment"
            ),
            synopsis: "Small astonishments, annotated closely enough that the notes begin to feel like another text beside the first.",
            lastImportedAt: Date().addingTimeInterval(-86_400 * 2),
            createdAt: Date().addingTimeInterval(-86_400 * 90),
            updatedAt: Date().addingTimeInterval(-86_400)
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
        ),
        HighlightSearchResult(
            highlight: highlights[1],
            book: BookReference(id: books[0].id, title: books[0].title, author: books[0].author),
            matchedTerms: ["world", "imagination"],
            snippet: "Whoever you are, no matter how lonely, the world offers itself to your imagination.",
            matchedInNote: false,
            matchedField: "text"
        )
    ]

    static let searchPage = PaginatedResponse(
        items: searchResults,
        pageInfo: PageInfo(page: 1, limit: 20, total: 2, hasMore: false, nextPage: nil)
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
        ),
        ImportRecord(
            id: "imp_second",
            status: .processing,
            summary: ImportSummary(
                booksDetected: 1,
                highlightsDetected: 11,
                notesDetected: 3,
                duplicatesDetected: 0,
                warningsCount: 0,
                warnings: []
            ),
            booksCreated: 0,
            booksUpdated: 1,
            filename: "Notebook Export.txt",
            source: "kindle_txt",
            createdAt: Date().addingTimeInterval(-1_200),
            completedAt: nil,
            message: "Import is still processing."
        )
    ]

    static let exportArtifact = ExportArtifact(
        format: .markdown,
        scope: .library,
        fileURL: URL(fileURLWithPath: "/tmp/fragmenta-preview.md"),
        generatedAt: Date(),
        byteCount: 4_096
    )
}
#endif
