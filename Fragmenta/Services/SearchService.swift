import Foundation

protocol SearchServiceProtocol {
    func searchHighlights(query: String) async throws -> [HighlightSearchResult]
}

struct SearchService: SearchServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func searchHighlights(query: String) async throws -> [HighlightSearchResult] {
        let trimmedQuery = query.trimmed

        guard trimmedQuery.isEmpty == false else {
            return []
        }

        return try await apiClient.request(.search(query: trimmedQuery))
    }
}
