import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var diagnostics = DiagnosticsSnapshot.empty
    @Published private(set) var exportStates: [ExportFormat: LoadableState<ExportArtifact>] = [:]
    @Published private(set) var lastImportResponse: ImportResponse?
    @Published private(set) var backendHealthCheck: BackendHealthCheck?
    @Published private(set) var isCheckingBackend = false
    @Published var baseURLOverrideDraft: String
    @Published private(set) var baseURLOverrideMessage: String?
    @Published private(set) var baseURLOverrideIsError = false
    @Published private(set) var cacheMessage: String?

    private let exportService: ExportServiceProtocol
    private let importService: ImportServiceProtocol
    private let backendDiagnosticsService: BackendDiagnosticsServiceProtocol
    private let diagnosticsStore: DiagnosticsStore

    init(
        exportService: ExportServiceProtocol,
        importService: ImportServiceProtocol,
        backendDiagnosticsService: BackendDiagnosticsServiceProtocol,
        diagnosticsStore: DiagnosticsStore,
        baseURLOverride: String
    ) {
        self.exportService = exportService
        self.importService = importService
        self.backendDiagnosticsService = backendDiagnosticsService
        self.diagnosticsStore = diagnosticsStore
        self.baseURLOverrideDraft = baseURLOverride
    }

    func load() {
        diagnostics = diagnosticsStore.snapshot()

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            lastImportResponse = await importService.loadCachedLastImportResponse()

            if backendHealthCheck == nil {
                await performBackendHealthCheck()
            }
        }
    }

    func export(_ format: ExportFormat) {
        exportStates[format] = .loading(previous: exportStates[format]?.value)

        Task { [weak self] in
            await self?.performExport(format)
        }
    }

    func applyBaseURLOverride(using appState: AppState) {
        switch appState.applyDevelopmentBaseURLOverride(baseURLOverrideDraft) {
        case .applied(let resolvedURL):
            baseURLOverrideDraft = appState.developmentBaseURLOverride
            baseURLOverrideMessage = "Applied development override: \(resolvedURL)"
            baseURLOverrideIsError = false
        case .cleared:
            baseURLOverrideDraft = appState.developmentBaseURLOverride
            baseURLOverrideMessage = "Cleared the development override. Fragmenta is back on the bundled base URL."
            baseURLOverrideIsError = false
        case .rejected(let message):
            baseURLOverrideMessage = message
            baseURLOverrideIsError = true
            return
        }

        backendHealthCheck = nil
        load()
    }

    func clearCache(using appState: AppState) {
        Task { [weak self] in
            await self?.performClearCache(using: appState)
        }
    }

    func runBackendHealthCheck() {
        Task { [weak self] in
            await self?.performBackendHealthCheck()
        }
    }

    func exportState(for format: ExportFormat) -> LoadableState<ExportArtifact> {
        exportStates[format] ?? .idle
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return error.localizedDescription
    }

    private func performExport(_ format: ExportFormat) async {
        do {
            let artifact = try await exportService.exportLibrary(format: format)
            exportStates[format] = .loaded(artifact, source: .remote)
            load()
        } catch is CancellationError {
            return
        } catch {
            exportStates[format] = .failed(Self.errorMessage(for: error), previous: exportStates[format]?.value)
        }
    }

    private func performClearCache(using appState: AppState) async {
        do {
            try await appState.clearCachedData()
            cacheMessage = "Local caches, including cover art, cleared."
            load()
        } catch {
            cacheMessage = Self.errorMessage(for: error)
        }
    }

    private func performBackendHealthCheck() async {
        isCheckingBackend = true
        defer { isCheckingBackend = false }

        backendHealthCheck = await backendDiagnosticsService.checkBackend()
        diagnostics = diagnosticsStore.snapshot()
    }
}
