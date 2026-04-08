import Foundation

protocol ShareCardServiceProtocol {
    func fetchShareCard(highlightID: String) async throws -> ShareCardArtifact
}

struct ShareCardService: ShareCardServiceProtocol {
    private let apiClient: APIClient
    private let diagnosticsStore: DiagnosticsStore
    private let fileManager: FileManager
    private let directoryURL: URL

    init(
        apiClient: APIClient,
        diagnosticsStore: DiagnosticsStore,
        fileManager: FileManager = .default
    ) {
        self.apiClient = apiClient
        self.diagnosticsStore = diagnosticsStore
        self.fileManager = fileManager

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.directoryURL = cachesDirectory.appendingPathComponent("FragmentaShareCards", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    func fetchShareCard(highlightID: String) async throws -> ShareCardArtifact {
        let cachedURL = cachedFileURL(for: highlightID)
        if fileManager.fileExists(atPath: cachedURL.path),
           let attributes = try? fileManager.attributesOfItem(atPath: cachedURL.path),
           let byteCount = attributes[.size] as? NSNumber,
           byteCount.intValue > 0 {
            return ShareCardArtifact(
                highlightID: highlightID,
                fileURL: cachedURL,
                generatedAt: .now,
                byteCount: byteCount.intValue,
                mimeType: "image/png"
            )
        }

        do {
            let response = try await downloadShareCard(highlightID: highlightID)
            let fileURL = response.filename
                .map { directoryURL.appendingPathComponent($0) }
                ?? cachedURL
            try response.data.write(to: fileURL, options: .atomic)

            let artifact = ShareCardArtifact(
                highlightID: highlightID,
                fileURL: fileURL,
                generatedAt: .now,
                byteCount: response.data.count,
                mimeType: response.mimeType
            )

            diagnosticsStore.record(
                event: .shareCard,
                status: .success,
                detail: "Prepared share card for highlight \(highlightID)."
            )

            return artifact
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .shareCard,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    private func cachedFileURL(for highlightID: String) -> URL {
        directoryURL.appendingPathComponent("highlight-\(highlightID)").appendingPathExtension("png")
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return error.localizedDescription
    }

    private func downloadShareCard(highlightID: String) async throws -> DownloadedResponse {
        let candidates: [(path: String, queryItems: [URLQueryItem])] = [
            ("/api/highlights/\(highlightID)/share-card", []),
            ("/api/share/highlight/\(highlightID)", [URLQueryItem(name: "download", value: "1")])
        ]

        var fallbackError: Error?

        for candidate in candidates {
            do {
                return try await apiClient.download(path: candidate.path, queryItems: candidate.queryItems)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                guard Self.shouldTryFallback(after: error) else {
                    throw error
                }

                fallbackError = error
            }
        }

        throw fallbackError ?? APIError.transport(statusCode: -1, message: "Unable to download share card.")
    }

    private static func shouldTryFallback(after error: Error) -> Bool {
        guard let apiError = error as? APIError, let statusCode = apiError.statusCode else {
            return false
        }

        return [400, 404, 405].contains(statusCode)
    }
}
