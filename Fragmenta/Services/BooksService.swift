import Foundation

protocol BooksServiceProtocol {
    func loadCachedBooks(query: LibraryQuery) async -> [Book]?
    func fetchBooks(query: LibraryQuery) async throws -> [Book]
    func loadCachedBookDetail(bookID: String) async -> BookDetail?
    func fetchBookDetail(bookID: String) async throws -> BookDetail
    func loadCachedHighlights(bookID: String, page: PageRequest) async -> PaginatedResponse<Highlight>?
    func fetchHighlights(bookID: String, page: PageRequest) async throws -> PaginatedResponse<Highlight>
    func fetchHighlight(id: String) async throws -> Highlight
}

struct BooksService: BooksServiceProtocol {
    private let apiClient: APIClient
    private let cacheStore: FragmentaCacheStore
    private let diagnosticsStore: DiagnosticsStore

    init(
        apiClient: APIClient,
        cacheStore: FragmentaCacheStore,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.diagnosticsStore = diagnosticsStore
    }

    func loadCachedBooks(query: LibraryQuery) async -> [Book]? {
        await cacheStore.load([Book].self, forKey: CacheKey.books(query))
    }

    func fetchBooks(query: LibraryQuery) async throws -> [Book] {
        do {
            let response: PaginatedResponse<Book> = try await apiClient.request(.books(query: query))
            let books = applyLocalRefinements(to: response.items, query: query)
            try await cacheStore.save(books, forKey: CacheKey.books(query))
            diagnosticsStore.record(
                event: .library,
                status: .success,
                detail: "Fetched \(books.count) books from \(query.sort.title.lowercased()) sort."
            )
            return books
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .library,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    func loadCachedBookDetail(bookID: String) async -> BookDetail? {
        await cacheStore.load(BookDetail.self, forKey: CacheKey.bookDetail(bookID))
    }

    func fetchBookDetail(bookID: String) async throws -> BookDetail {
        let payload: BookMetadataPayload = try await apiClient.request(.book(id: bookID))

        let detail = BookDetail(
            book: payload.book,
            stats: payload.stats ?? BookDetail.Stats(
                highlightCount: payload.book.highlightCount,
                noteCount: payload.book.noteCount ?? 0,
                lastImportedAt: payload.book.lastImportedAt,
                firstHighlightAt: nil,
                latestHighlightAt: payload.book.updatedAt
            )
        )

        try await cacheStore.save(detail, forKey: CacheKey.bookDetail(bookID))
        return detail
    }

    func loadCachedHighlights(bookID: String, page: PageRequest) async -> PaginatedResponse<Highlight>? {
        await cacheStore.load(PaginatedResponse<Highlight>.self, forKey: CacheKey.highlights(bookID: bookID, page: page))
    }

    func fetchHighlights(bookID: String, page: PageRequest) async throws -> PaginatedResponse<Highlight> {
        let response: PaginatedResponse<Highlight> = try await apiClient.request(.highlights(bookID: bookID, page: page))
        try await cacheStore.save(response, forKey: CacheKey.highlights(bookID: bookID, page: page))
        return response
    }

    func fetchHighlight(id: String) async throws -> Highlight {
        try await apiClient.request(.highlight(id: id))
    }

    private func applyLocalRefinements(to books: [Book], query: LibraryQuery) -> [Book] {
        let filtered = books.filter { book in
            let sourceMatches = query.source == .all || book.source.rawValue == query.source.rawValue
            let recentMatches = query.recentOnly == false || book.isRecentlyImported
            let notesMatch = query.hasNotesOnly == false || (book.noteCount ?? 0) > 0
            return sourceMatches && recentMatches && notesMatch
        }

        switch query.sort {
        case .recentlyImported:
            return filtered.sorted { lhs, rhs in
                (lhs.lastImportedAt ?? lhs.updatedAt ?? .distantPast) > (rhs.lastImportedAt ?? rhs.updatedAt ?? .distantPast)
            }
        case .title:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .author:
            return filtered.sorted { $0.displayAuthor.localizedCaseInsensitiveCompare($1.displayAuthor) == .orderedAscending }
        case .highlightCount:
            return filtered.sorted { $0.highlightCount > $1.highlightCount }
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return error.localizedDescription
    }
}

private enum CacheKey {
    static func books(_ query: LibraryQuery) -> String {
        "books-\(query.sort.rawValue)-\(query.source.rawValue)-recent:\(query.recentOnly)-notes:\(query.hasNotesOnly)"
    }

    static func bookDetail(_ bookID: String) -> String {
        "book-detail-\(bookID)"
    }

    static func highlights(bookID: String, page: PageRequest) -> String {
        "book-highlights-\(bookID)-page:\(page.page)-limit:\(page.limit)"
    }
}
