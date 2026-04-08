import Foundation

protocol SearchServiceProtocol {
    func recentSearches(limit: Int) -> [String]
    func clearRecentSearches()
    func loadCachedSearchResults(query: SearchQuery, page: PageRequest) async -> PaginatedResponse<HighlightSearchResult>?
    func searchHighlights(query: SearchQuery, page: PageRequest) async throws -> PaginatedResponse<HighlightSearchResult>
}

struct SearchService: SearchServiceProtocol {
    private let apiClient: APIClient
    private let cacheStore: FragmentaCacheStore
    private let preferencesStore: AppPreferencesStore
    private let diagnosticsStore: DiagnosticsStore

    init(
        apiClient: APIClient,
        cacheStore: FragmentaCacheStore,
        preferencesStore: AppPreferencesStore,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.preferencesStore = preferencesStore
        self.diagnosticsStore = diagnosticsStore
    }

    func recentSearches(limit: Int = 8) -> [String] {
        preferencesStore.recentSearches(limit: limit)
    }

    func clearRecentSearches() {
        preferencesStore.clearRecentSearches()
    }

    func loadCachedSearchResults(query: SearchQuery, page: PageRequest) async -> PaginatedResponse<HighlightSearchResult>? {
        await cacheStore.load(PaginatedResponse<HighlightSearchResult>.self, forKey: CacheKey.results(query: query, page: page))
    }

    func searchHighlights(query: SearchQuery, page: PageRequest) async throws -> PaginatedResponse<HighlightSearchResult> {
        let trimmedQuery = query.trimmedText
        let hasFilters = query.hasActiveFilters

        guard trimmedQuery.isEmpty == false || hasFilters else {
            return PaginatedResponse(items: [], pageInfo: .singlePage(itemCount: 0, limit: page.limit))
        }

        do {
            let response: PaginatedResponse<HighlightSearchResult> = try await apiClient.request(.search(query: query, page: page))
            try await cacheStore.save(response, forKey: CacheKey.results(query: query, page: page))
            if trimmedQuery.isEmpty == false {
                preferencesStore.saveRecentSearch(trimmedQuery)
            }
            diagnosticsStore.record(
                event: .search,
                status: .success,
                detail: Self.diagnosticsMessage(for: query, resultCount: response.items.count)
            )
            return response
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .search,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return error.localizedDescription
    }

    private static func diagnosticsMessage(for query: SearchQuery, resultCount: Int) -> String {
        let modeDescriptor = query.mode == .semantic ? "semantic " : ""

        if query.trimmedText.isEmpty == false {
            return "\(modeDescriptor.capitalized)search for “\(query.trimmedText)” returned \(resultCount) results."
        }

        if let bookID = query.bookID {
            return "\(modeDescriptor.capitalized)filtered search for book \(bookID) returned \(resultCount) results."
        }

        if query.author.isBlank == false {
            return "\(modeDescriptor.capitalized)author-filtered search for \(query.author.trimmed) returned \(resultCount) results."
        }

        return "\(modeDescriptor.capitalized)filtered search returned \(resultCount) results."
    }
}

private enum CacheKey {
    static func results(query: SearchQuery, page: PageRequest) -> String {
        "search-\(query.mode.rawValue)-\(query.sort.rawValue)-book:\(query.bookID ?? "all")-author:\(query.author.trimmed)-notes:\(query.hasNotesOnly)-text:\(query.trimmedText)-page:\(page.page)-limit:\(page.limit)"
    }
}
