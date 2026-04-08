import Foundation

struct AppContainer {
    let config: AppConfig
    let cacheStore: FragmentaCacheStore
    let preferencesStore: AppPreferencesStore
    let diagnosticsStore: DiagnosticsStore
    let sharedImportStore: SharedImportStore
    let booksService: BooksServiceProtocol
    let insightsService: InsightsServiceProtocol
    let collectionsService: CollectionsServiceProtocol
    let searchService: SearchServiceProtocol
    let discoveryService: DiscoveryServiceProtocol
    let shareCardService: ShareCardServiceProtocol
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
            insightsService: InsightsService(
                apiClient: apiClient,
                cacheStore: cacheStore,
                diagnosticsStore: diagnosticsStore
            ),
            collectionsService: CollectionsService(
                apiClient: apiClient,
                cacheStore: cacheStore,
                diagnosticsStore: diagnosticsStore
            ),
            searchService: SearchService(
                apiClient: apiClient,
                cacheStore: cacheStore,
                preferencesStore: preferencesStore,
                diagnosticsStore: diagnosticsStore
            ),
            discoveryService: DiscoveryService(
                apiClient: apiClient,
                cacheStore: cacheStore,
                diagnosticsStore: diagnosticsStore
            ),
            shareCardService: ShareCardService(
                apiClient: apiClient,
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
