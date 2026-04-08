import Foundation

protocol InsightsServiceProtocol {
    func loadCachedInsights() async -> ReadingInsights?
    func fetchInsights() async throws -> ReadingInsights
}

struct InsightsService: InsightsServiceProtocol {
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

    func loadCachedInsights() async -> ReadingInsights? {
        await cacheStore.load(ReadingInsights.self, forKey: CacheKey.insights)
    }

    func fetchInsights() async throws -> ReadingInsights {
        do {
            let insights: ReadingInsights = try await apiClient.request(.readingInsights())
            try await cacheStore.save(insights, forKey: CacheKey.insights)
            diagnosticsStore.record(
                event: .insights,
                status: .success,
                detail: "Fetched reading insights for \(insights.totals.bookCount) books."
            )
            return insights
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .insights,
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
}

private enum CacheKey {
    static let insights = "reading-insights"
}
