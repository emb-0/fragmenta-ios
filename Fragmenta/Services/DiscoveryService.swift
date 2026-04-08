import Foundation

protocol DiscoveryServiceProtocol {
    func loadCachedBookDiscovery(bookID: String) async -> BookDiscovery?
    func fetchBookDiscovery(bookID: String) async throws -> BookDiscovery
}

struct DiscoveryService: DiscoveryServiceProtocol {
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

    func loadCachedBookDiscovery(bookID: String) async -> BookDiscovery? {
        await cacheStore.load(BookDiscoveryCachePayload.self, forKey: CacheKey.bookDiscovery(bookID))?.discovery
    }

    func fetchBookDiscovery(bookID: String) async throws -> BookDiscovery {
        async let summaryResult = fetchSummary(bookID: bookID)
        async let relatedResult = fetchRelatedHighlights(bookID: bookID)

        let summaryPayload: BookSummaryPayload
        let relatedHighlights: [BookDiscovery.RelatedHighlight]

        do {
            summaryPayload = try await summaryResult
        } catch {
            if Self.isUnsupportedAIError(error) {
                summaryPayload = BookSummaryPayload()
            } else {
                throw error
            }
        }

        do {
            relatedHighlights = try await relatedResult
        } catch {
            if Self.isUnsupportedAIError(error) {
                relatedHighlights = []
            } else {
                throw error
            }
        }

        let discovery = BookDiscovery(
            summary: summaryPayload.summary,
            themes: summaryPayload.themes,
            relatedHighlights: relatedHighlights,
            updatedAt: summaryPayload.updatedAt
        )

        try await cacheStore.save(BookDiscoveryCachePayload(discovery: discovery), forKey: CacheKey.bookDiscovery(bookID))

        diagnosticsStore.record(
            event: .discovery,
            status: .success,
            detail: discovery.isEmpty
                ? "AI discovery unavailable or empty for book \(bookID)."
                : "Loaded discovery summary for book \(bookID)."
        )

        return discovery
    }

    private func fetchSummary(bookID: String) async throws -> BookSummaryPayload {
        try await apiClient.request(.bookSummary(id: bookID))
    }

    private func fetchRelatedHighlights(bookID: String) async throws -> [BookDiscovery.RelatedHighlight] {
        let response: PaginatedResponse<BookDiscovery.RelatedHighlight> = try await apiClient.request(.relatedHighlights(bookID: bookID))
        return response.items
    }

    private static func isUnsupportedAIError(_ error: Error) -> Bool {
        guard let apiError = error as? APIError, let statusCode = apiError.statusCode else {
            return false
        }

        return [400, 404, 405, 501].contains(statusCode)
    }
}

private struct BookDiscoveryCachePayload: Codable, Hashable, Sendable {
    let summary: String?
    let themes: [BookDiscovery.Theme]
    let relatedHighlights: [BookDiscovery.RelatedHighlight]
    let updatedAt: Date?

    init(discovery: BookDiscovery) {
        self.summary = discovery.summary
        self.themes = discovery.themes
        self.relatedHighlights = discovery.relatedHighlights
        self.updatedAt = discovery.updatedAt
    }

    var discovery: BookDiscovery {
        BookDiscovery(
            summary: summary,
            themes: themes,
            relatedHighlights: relatedHighlights,
            updatedAt: updatedAt
        )
    }
}

private enum CacheKey {
    static func bookDiscovery(_ bookID: String) -> String {
        "book-discovery-\(bookID)"
    }
}
