import Foundation

protocol ImportServiceProtocol {
    func loadCachedImports() async -> [ImportRecord]?
    func loadCachedLastImportResponse() async -> ImportResponse?
    func previewKindleImport(rawText: String, filename: String?) async throws -> ImportPreview
    func importKindleHighlights(rawText: String, filename: String?) async throws -> ImportResponse
    func fetchImports(page: PageRequest) async throws -> PaginatedResponse<ImportRecord>
    func fetchImport(id: String) async throws -> ImportRecord
}

struct ImportService: ImportServiceProtocol {
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

    func loadCachedImports() async -> [ImportRecord]? {
        await cacheStore.load([ImportRecord].self, forKey: CacheKey.history)
    }

    func loadCachedLastImportResponse() async -> ImportResponse? {
        await cacheStore.load(ImportResponse.self, forKey: CacheKey.lastImportResponse)
    }

    func previewKindleImport(rawText: String, filename: String? = nil) async throws -> ImportPreview {
        let request = ImportRequest(
            source: .kindleText,
            rawText: rawText.trimmed,
            filename: filename,
            dryRun: true
        )

        do {
            let preview: ImportPreview = try await apiClient.request(.kindleImportPreview(request: request))
            try await cacheStore.save(preview, forKey: CacheKey.lastPreview)
            diagnosticsStore.record(
                event: .importPreview,
                status: .success,
                detail: "Preview detected \(preview.summary.highlightsDetected) highlights."
            )
            return preview
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .importPreview,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    func importKindleHighlights(rawText: String, filename: String? = nil) async throws -> ImportResponse {
        let request = ImportRequest(
            source: .kindleText,
            rawText: rawText.trimmed,
            filename: filename,
            dryRun: false
        )

        do {
            let response: ImportResponse = try await apiClient.request(.kindleImport(request: request))
            try await cacheStore.save(response, forKey: CacheKey.lastImportResponse)
            diagnosticsStore.record(
                event: .importCommit,
                status: .success,
                detail: "Import \(response.importID) completed with \(response.summary.highlightsDetected) highlights."
            )
            return response
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .importCommit,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    func fetchImports(page: PageRequest) async throws -> PaginatedResponse<ImportRecord> {
        let response: PaginatedResponse<ImportRecord> = try await apiClient.request(.imports(page: page))
        if page.page == 1 {
            try await cacheStore.save(response.items, forKey: CacheKey.history)
        }
        return response
    }

    func fetchImport(id: String) async throws -> ImportRecord {
        try await apiClient.request(.importRecord(id: id))
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return error.localizedDescription
    }
}

private enum CacheKey {
    static let history = "imports-history"
    static let lastPreview = "imports-last-preview"
    static let lastImportResponse = "imports-last-response"
}
