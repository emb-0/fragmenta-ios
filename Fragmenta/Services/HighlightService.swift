import Foundation

protocol HighlightServiceProtocol {
    func importKindleHighlights(rawText: String, filename: String?) async throws -> ImportResponse
}

struct HighlightService: HighlightServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func importKindleHighlights(rawText: String, filename: String? = nil) async throws -> ImportResponse {
        let request = ImportRequest(
            source: .kindleText,
            rawText: rawText.trimmed,
            filename: filename,
            dryRun: false
        )

        return try await apiClient.request(.kindleImport(request: request))
    }
}
