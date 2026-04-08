import Foundation

#if DEBUG
struct PreviewBooksService: BooksServiceProtocol {
    func loadCachedBooks(query: LibraryQuery) async -> [Book]? {
        PreviewFixtures.books
    }

    func fetchBooks(query: LibraryQuery) async throws -> [Book] {
        PreviewFixtures.books
    }

    func loadCachedBookDetail(bookID: String) async -> BookDetail? {
        PreviewFixtures.bookDetail
    }

    func fetchBookDetail(bookID: String) async throws -> BookDetail {
        PreviewFixtures.bookDetail
    }

    func loadCachedHighlights(bookID: String, page: PageRequest) async -> PaginatedResponse<Highlight>? {
        PreviewFixtures.highlightPage
    }

    func fetchHighlights(bookID: String, page: PageRequest) async throws -> PaginatedResponse<Highlight> {
        PreviewFixtures.highlightPage
    }

    func fetchHighlight(id: String) async throws -> Highlight {
        PreviewFixtures.highlights[0]
    }
}

struct PreviewSearchService: SearchServiceProtocol {
    func recentSearches(limit: Int) -> [String] {
        ["astonished", "attention", "wild geese"]
    }

    func clearRecentSearches() {}

    func loadCachedSearchResults(query: SearchQuery, page: PageRequest) async -> PaginatedResponse<HighlightSearchResult>? {
        PreviewFixtures.searchPage
    }

    func searchHighlights(query: SearchQuery, page: PageRequest) async throws -> PaginatedResponse<HighlightSearchResult> {
        PreviewFixtures.searchPage
    }
}

struct PreviewInsightsService: InsightsServiceProtocol {
    func loadCachedInsights() async -> ReadingInsights? {
        PreviewFixtures.readingInsights
    }

    func fetchInsights() async throws -> ReadingInsights {
        PreviewFixtures.readingInsights
    }
}

struct PreviewCollectionsService: CollectionsServiceProtocol {
    func loadCachedCollections() async -> [Collection]? {
        PreviewFixtures.collections
    }

    func fetchCollections(page: PageRequest) async throws -> PaginatedResponse<Collection> {
        PaginatedResponse(
            items: PreviewFixtures.collections,
            pageInfo: PageInfo.singlePage(itemCount: PreviewFixtures.collections.count, limit: page.limit)
        )
    }

    func loadCachedCollectionDetail(id: String) async -> CollectionDetail? {
        PreviewFixtures.collectionDetail
    }

    func fetchCollectionDetail(id: String) async throws -> CollectionDetail {
        PreviewFixtures.collectionDetail
    }

    func loadCachedCollections(forBookID bookID: String) async -> [Collection]? {
        PreviewFixtures.collections.filter { $0.containsBook == true }
    }

    func fetchCollections(forBookID bookID: String, page: PageRequest) async throws -> PaginatedResponse<Collection> {
        PaginatedResponse(
            items: PreviewFixtures.collections.filter { $0.containsBook == true },
            pageInfo: PageInfo.singlePage(itemCount: PreviewFixtures.collections.filter { $0.containsBook == true }.count, limit: page.limit)
        )
    }

    func addBook(_ bookID: String, toCollection collectionID: String) async throws {}

    func removeBook(_ bookID: String, fromCollection collectionID: String) async throws {}
}

struct PreviewDiscoveryService: DiscoveryServiceProtocol {
    func loadCachedBookDiscovery(bookID: String) async -> BookDiscovery? {
        PreviewFixtures.bookDiscovery
    }

    func fetchBookDiscovery(bookID: String) async throws -> BookDiscovery {
        PreviewFixtures.bookDiscovery
    }
}

struct PreviewShareCardService: ShareCardServiceProtocol {
    func fetchShareCard(highlightID: String) async throws -> ShareCardArtifact {
        PreviewFixtures.shareCardArtifact
    }
}

struct PreviewImportService: ImportServiceProtocol {
    func loadCachedImports() async -> [ImportRecord]? {
        PreviewFixtures.importRecords
    }

    func loadCachedLastImportResponse() async -> ImportResponse? {
        PreviewFixtures.importResponse
    }

    func previewKindleImport(rawText: String, filename: String?) async throws -> ImportPreview {
        PreviewFixtures.importPreview
    }

    func importKindleHighlights(rawText: String, filename: String?) async throws -> ImportResponse {
        PreviewFixtures.importResponse
    }

    func fetchImports(page: PageRequest) async throws -> PaginatedResponse<ImportRecord> {
        PaginatedResponse(
            items: PreviewFixtures.importRecords,
            pageInfo: PageInfo(page: 1, limit: 10, total: PreviewFixtures.importRecords.count, hasMore: false, nextPage: nil)
        )
    }

    func fetchImport(id: String) async throws -> ImportRecord {
        PreviewFixtures.importRecords[0]
    }
}

struct PreviewExportService: ExportServiceProtocol {
    func exportLibrary(format: ExportFormat) async throws -> ExportArtifact {
        PreviewFixtures.exportArtifact
    }

    func exportBook(bookID: String, format: ExportFormat) async throws -> ExportArtifact {
        PreviewFixtures.exportArtifact
    }
}

extension AppConfig {
    static let preview = AppConfig(
        apiBaseURL: URL(string: "https://preview.fragmenta.local")!,
        defaultAPIBaseURL: URL(string: "https://preview.fragmenta.local")!,
        requestTimeout: 20,
        appDisplayName: "Fragmenta",
        appVersion: "0.6.0",
        buildNumber: "6",
        appGroupIdentifier: "group.preview.fragmenta"
    )
}

extension AppContainer {
    static let preview = AppContainer(
        config: .preview,
        cacheStore: FragmentaCacheStore(),
        preferencesStore: AppPreferencesStore(),
        diagnosticsStore: DiagnosticsStore(),
        sharedImportStore: SharedImportStore(appGroupIdentifier: AppConfig.preview.appGroupIdentifier),
        booksService: PreviewBooksService(),
        insightsService: PreviewInsightsService(),
        collectionsService: PreviewCollectionsService(),
        searchService: PreviewSearchService(),
        discoveryService: PreviewDiscoveryService(),
        shareCardService: PreviewShareCardService(),
        importService: PreviewImportService(),
        exportService: PreviewExportService()
    )
}
#endif
