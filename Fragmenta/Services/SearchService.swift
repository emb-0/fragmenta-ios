import Foundation

protocol SearchServiceProtocol {
    func recentSearches(limit: Int) -> [String]
    func clearRecentSearches()
    func searchHighlights(query: SearchQuery, page: PageRequest) async throws -> PaginatedResponse<HighlightSearchResult>
}

struct SearchService: SearchServiceProtocol {
    private let apiClient: APIClient
    private let preferencesStore: AppPreferencesStore
    private let diagnosticsStore: DiagnosticsStore

    init(
        apiClient: APIClient,
        preferencesStore: AppPreferencesStore,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.apiClient = apiClient
        self.preferencesStore = preferencesStore
        self.diagnosticsStore = diagnosticsStore
    }

    func recentSearches(limit: Int = 8) -> [String] {
        preferencesStore.recentSearches(limit: limit)
    }

    func clearRecentSearches() {
        preferencesStore.clearRecentSearches()
    }

    func searchHighlights(query: SearchQuery, page: PageRequest) async throws -> PaginatedResponse<HighlightSearchResult> {
        let trimmedQuery = query.trimmedText
        let hasFilters = query.hasActiveFilters

        guard trimmedQuery.isEmpty == false || hasFilters else {
            return PaginatedResponse(items: [], pageInfo: .singlePage(itemCount: 0, limit: page.limit))
        }

        do {
            let response: PaginatedResponse<HighlightSearchResult> = try await apiClient.request(.search(query: query, page: page))
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
        if query.trimmedText.isEmpty == false {
            return "Search for “\(query.trimmedText)” returned \(resultCount) results."
        }

        if let bookID = query.bookID {
            return "Filtered search for book \(bookID) returned \(resultCount) results."
        }

        if query.author.isBlank == false {
            return "Author-filtered search for \(query.author.trimmed) returned \(resultCount) results."
        }

        return "Filtered search returned \(resultCount) results."
    }
}
