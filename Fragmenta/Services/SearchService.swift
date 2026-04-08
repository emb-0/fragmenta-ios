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
            let remotePage = remotePageRequest(for: query, page: page)
            let response: PaginatedResponse<HighlightSearchResult> = try await apiClient.request(.search(query: query, page: remotePage))
            let refinedResponse = applyLocalRefinements(to: response, query: query, requestedPage: page, remotePage: remotePage)
            try await cacheStore.save(refinedResponse, forKey: CacheKey.results(query: query, page: page))
            if trimmedQuery.isEmpty == false {
                preferencesStore.saveRecentSearch(trimmedQuery)
            }
            diagnosticsStore.record(
                event: .search,
                status: .success,
                detail: Self.diagnosticsMessage(for: query, resultCount: refinedResponse.items.count)
            )
            return refinedResponse
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

    private func remotePageRequest(for query: SearchQuery, page: PageRequest) -> PageRequest {
        if requiresLocalRefinement(for: query) {
            return PageRequest(page: 1, limit: max(page.limit, 80))
        }

        return page
    }

    private func applyLocalRefinements(
        to response: PaginatedResponse<HighlightSearchResult>,
        query: SearchQuery,
        requestedPage: PageRequest,
        remotePage: PageRequest
    ) -> PaginatedResponse<HighlightSearchResult> {
        var results = response.items

        if query.author.isBlank == false {
            let authorFilter = query.author.trimmed
            results = results.filter {
                ($0.book.author ?? "").localizedCaseInsensitiveContains(authorFilter)
            }
        }

        switch query.sort {
        case .oldest:
            results.sort {
                chronologicalRank(for: $0.highlight) < chronologicalRank(for: $1.highlight)
            }
        case .newest:
            results.sort {
                chronologicalRank(for: $0.highlight) > chronologicalRank(for: $1.highlight)
            }
        case .relevance:
            break
        }

        if remotePage != requestedPage {
            return PaginatedResponse(
                items: results,
                pageInfo: PageInfo.singlePage(itemCount: results.count, limit: max(results.count, requestedPage.limit))
            )
        }

        return PaginatedResponse(items: results, pageInfo: response.pageInfo)
    }

    private func requiresLocalRefinement(for query: SearchQuery) -> Bool {
        query.author.isBlank == false || query.sort == .oldest
    }

    private func chronologicalRank(for highlight: Highlight) -> Date {
        highlight.highlightedAt
            ?? highlight.createdAt
            ?? highlight.updatedAt
            ?? .distantPast
    }
}

private enum CacheKey {
    static func results(query: SearchQuery, page: PageRequest) -> String {
        "search-\(query.mode.rawValue)-\(query.sort.rawValue)-book:\(query.bookID ?? "all")-author:\(query.author.trimmed)-notes:\(query.hasNotesOnly)-text:\(query.trimmedText)-page:\(page.page)-limit:\(page.limit)"
    }
}
