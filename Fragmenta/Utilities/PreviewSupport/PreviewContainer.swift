import Foundation

#if DEBUG
struct PreviewBooksService: BooksServiceProtocol {
    func fetchBooks() async throws -> [Book] {
        PreviewFixtures.books
    }

    func fetchBookDetail(bookID: String) async throws -> BookDetail {
        PreviewFixtures.bookDetail
    }

    func fetchHighlights(bookID: String) async throws -> [Highlight] {
        PreviewFixtures.highlights
    }
}

struct PreviewSearchService: SearchServiceProtocol {
    func searchHighlights(query: String) async throws -> [HighlightSearchResult] {
        PreviewFixtures.searchResults
    }
}

struct PreviewHighlightService: HighlightServiceProtocol {
    func importKindleHighlights(rawText: String, filename: String?) async throws -> ImportResponse {
        PreviewFixtures.importResponse
    }
}

extension AppConfig {
    static let preview = AppConfig(
        apiBaseURL: URL(string: "https://preview.fragmenta.local")!,
        requestTimeout: 20,
        appDisplayName: "Fragmenta"
    )
}

extension AppContainer {
    static let preview = AppContainer(
        config: .preview,
        booksService: PreviewBooksService(),
        searchService: PreviewSearchService(),
        highlightService: PreviewHighlightService()
    )
}
#endif
