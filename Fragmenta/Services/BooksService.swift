import Foundation

protocol BooksServiceProtocol {
    func fetchBooks() async throws -> [Book]
    func fetchBookDetail(bookID: String) async throws -> BookDetail
    func fetchHighlights(bookID: String) async throws -> [Highlight]
}

struct BooksService: BooksServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchBooks() async throws -> [Book] {
        let books = try await apiClient.request(.books())
        return books.sorted { lhs, rhs in
            (lhs.updatedAt ?? lhs.lastImportedAt ?? .distantPast) > (rhs.updatedAt ?? rhs.lastImportedAt ?? .distantPast)
        }
    }

    func fetchBookDetail(bookID: String) async throws -> BookDetail {
        async let metadata: BookMetadataPayload = apiClient.request(.book(id: bookID))
        async let highlights = fetchHighlights(bookID: bookID)

        let payload = try await metadata
        let loadedHighlights = try await highlights
        let noteCount = loadedHighlights.filter { !($0.note?.isBlank ?? true) }.count

        let stats = payload.stats ?? BookDetail.Stats(
            highlightCount: loadedHighlights.count,
            noteCount: noteCount,
            lastImportedAt: payload.book.lastImportedAt
        )

        return BookDetail(
            book: payload.book,
            highlights: loadedHighlights,
            stats: stats
        )
    }

    func fetchHighlights(bookID: String) async throws -> [Highlight] {
        try await apiClient.request(.highlights(bookID: bookID))
    }
}
