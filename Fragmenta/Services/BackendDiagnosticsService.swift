import Foundation

protocol BackendDiagnosticsServiceProtocol {
    func checkBackend() async -> BackendHealthCheck
}

struct BackendDiagnosticsService: BackendDiagnosticsServiceProtocol {
    private let config: AppConfig
    private let apiClient: APIClient
    private let diagnosticsStore: DiagnosticsStore

    init(
        config: AppConfig,
        apiClient: APIClient,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.config = config
        self.apiClient = apiClient
        self.diagnosticsStore = diagnosticsStore
    }

    func checkBackend() async -> BackendHealthCheck {
        let result: BackendHealthCheck

        if let issue = config.baseURLConfigurationIssue, config.isUsingFallbackAPIBaseURL {
            result = BackendHealthCheck(
                status: .invalidConfiguration,
                summary: issue,
                detail: "Fragmenta is using a safe fallback URL until the configured base URL is corrected.",
                checkedAt: .now,
                primaryPath: "/api/health",
                fallbackPath: nil
            )
        } else {
            result = await performReachabilityCheck()
        }

        diagnosticsStore.record(
            event: .backend,
            status: isSuccessful(result.status) ? .success : .failure,
            detail: result.summary
        )

        return result
    }

    private func performReachabilityCheck() async -> BackendHealthCheck {
        do {
            let payload: BackendHealthPayload = try await apiClient.request(APIEndpoint(path: "/api/health"))
            let statusDetail = payload.status ?? (payload.ok == true ? "ok" : nil)

            return BackendHealthCheck(
                status: .healthy,
                summary: "Health check succeeded against /api/health.",
                detail: statusDetail,
                checkedAt: .now,
                primaryPath: "/api/health",
                fallbackPath: nil
            )
        } catch let apiError as APIError where [404, 405].contains(apiError.statusCode ?? -1) {
            return await performStatsFallback(primaryError: apiError)
        } catch {
            return checkFailure(from: error, primaryPath: "/api/health", fallbackPath: nil)
        }
    }

    private func performStatsFallback(primaryError: APIError) async -> BackendHealthCheck {
        do {
            let _: BackendStatsProbePayload = try await apiClient.request(APIEndpoint(path: "/api/stats/overview"))
            return BackendHealthCheck(
                status: .reachableWithoutHealthEndpoint,
                summary: "fragmenta-core is reachable, but /api/health is not implemented yet.",
                detail: "The app successfully reached /api/stats/overview after /api/health returned \(primaryError.statusCode ?? 404).",
                checkedAt: .now,
                primaryPath: "/api/health",
                fallbackPath: "/api/stats/overview"
            )
        } catch {
            return checkFailure(
                from: error,
                primaryPath: "/api/health",
                fallbackPath: "/api/stats/overview"
            )
        }
    }

    private func checkFailure(
        from error: Error,
        primaryPath: String,
        fallbackPath: String?
    ) -> BackendHealthCheck {
        let apiError = (error as? APIError) ?? APIError.transport(statusCode: -1, message: error.localizedDescription)
        let status: BackendHealthCheck.Status

        switch apiError.category {
        case .offline:
            status = .unreachable
        case .server:
            status = .serverError
        case .decoding:
            status = .decodingMismatch
        default:
            status = .requestFailed
        }

        return BackendHealthCheck(
            status: status,
            summary: apiError.message,
            detail: apiError.details,
            checkedAt: .now,
            primaryPath: primaryPath,
            fallbackPath: fallbackPath
        )
    }

    private func isSuccessful(_ status: BackendHealthCheck.Status) -> Bool {
        switch status {
        case .healthy, .reachableWithoutHealthEndpoint:
            return true
        case .invalidConfiguration, .unreachable, .serverError, .decodingMismatch, .requestFailed:
            return false
        }
    }
}

private struct BackendHealthPayload: Decodable, Sendable {
    let ok: Bool?
    let status: String?
    let message: String?
}

private struct BackendStatsProbePayload: Decodable, Sendable {
    let bookCount: Int?
    let highlightCount: Int?
    let noteCount: Int?
}
