import Foundation

protocol ExportServiceProtocol {
    func exportLibrary(format: ExportFormat) async throws -> ExportArtifact
    func exportBook(bookID: String, format: ExportFormat) async throws -> ExportArtifact
}

struct ExportService: ExportServiceProtocol {
    private let apiClient: APIClient
    private let diagnosticsStore: DiagnosticsStore

    init(
        apiClient: APIClient,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.apiClient = apiClient
        self.diagnosticsStore = diagnosticsStore
    }

    func exportLibrary(format: ExportFormat) async throws -> ExportArtifact {
        try await export(scope: .library, format: format)
    }

    func exportBook(bookID: String, format: ExportFormat) async throws -> ExportArtifact {
        try await export(scope: .book(bookID: bookID), format: format)
    }

    private func export(scope: ExportScope, format: ExportFormat) async throws -> ExportArtifact {
        do {
            let response = try await apiClient.download(path: format.path, queryItems: scope.queryItems)
            let scopeDescriptor: String
            switch scope {
            case .library:
                scopeDescriptor = "library"
            case .book(let bookID):
                scopeDescriptor = "book-\(bookID)"
            }

            let filename = response.filename ?? "fragmenta-\(scopeDescriptor)-\(ISO8601DateFormatter().string(from: .now)).\(format.fileExtension)"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try response.data.write(to: fileURL, options: .atomic)

            let artifact = ExportArtifact(
                format: format,
                scope: scope,
                fileURL: fileURL,
                generatedAt: .now,
                byteCount: response.data.count
            )

            diagnosticsStore.record(
                event: .exports,
                status: .success,
                detail: "Prepared \(format.title) export (\(response.data.count) bytes)."
            )

            return artifact
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .exports,
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
