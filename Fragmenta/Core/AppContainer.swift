import Foundation

struct AppContainer {
    let config: AppConfig
    let cacheStore: FragmentaCacheStore
    let preferencesStore: AppPreferencesStore
    let diagnosticsStore: DiagnosticsStore
    let sharedImportStore: SharedImportStore
    let booksService: BooksServiceProtocol
    let searchService: SearchServiceProtocol
    let importService: ImportServiceProtocol
    let exportService: ExportServiceProtocol

    static func live(
        preferencesStore: AppPreferencesStore = AppPreferencesStore()
    ) -> AppContainer {
        let config = AppConfig.live(baseURLOverride: preferencesStore.developmentBaseURLOverride)
        let diagnosticsStore = DiagnosticsStore()
        let cacheStore = FragmentaCacheStore()
        let sharedImportStore = SharedImportStore(appGroupIdentifier: config.appGroupIdentifier)
        let apiClient = APIClient(
            config: config,
            headersProvider: PublicRequestHeadersProvider()
        )

        return AppContainer(
            config: config,
            cacheStore: cacheStore,
            preferencesStore: preferencesStore,
            diagnosticsStore: diagnosticsStore,
            sharedImportStore: sharedImportStore,
            booksService: BooksService(
                apiClient: apiClient,
                cacheStore: cacheStore,
                diagnosticsStore: diagnosticsStore
            ),
            searchService: SearchService(
                apiClient: apiClient,
                preferencesStore: preferencesStore,
                diagnosticsStore: diagnosticsStore
            ),
            importService: ImportService(
                apiClient: apiClient,
                cacheStore: cacheStore,
                diagnosticsStore: diagnosticsStore
            ),
            exportService: ExportService(
                apiClient: apiClient,
                diagnosticsStore: diagnosticsStore
            )
        )
    }
}
