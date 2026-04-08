import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var diagnostics = DiagnosticsSnapshot.empty
    @Published private(set) var exportStates: [ExportFormat: LoadableState<ExportArtifact>] = [:]
    @Published private(set) var lastImportResponse: ImportResponse?
    @Published var baseURLOverrideDraft: String
    @Published private(set) var cacheMessage: String?

    private let exportService: ExportServiceProtocol
    private let importService: ImportServiceProtocol
    private let diagnosticsStore: DiagnosticsStore

    init(
        exportService: ExportServiceProtocol,
        importService: ImportServiceProtocol,
        diagnosticsStore: DiagnosticsStore,
        baseURLOverride: String
    ) {
        self.exportService = exportService
        self.importService = importService
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
        }
    }

    func export(_ format: ExportFormat) {
        exportStates[format] = .loading(previous: exportStates[format]?.value)

        Task { [weak self] in
            await self?.performExport(format)
        }
    }

    func applyBaseURLOverride(using appState: AppState) {
        appState.applyDevelopmentBaseURLOverride(baseURLOverrideDraft)
        baseURLOverrideDraft = appState.developmentBaseURLOverride
    }

    func clearCache(using appState: AppState) {
        Task { [weak self] in
            await self?.performClearCache(using: appState)
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
            cacheMessage = "Local caches cleared."
            load()
        } catch {
            cacheMessage = Self.errorMessage(for: error)
        }
    }
}
