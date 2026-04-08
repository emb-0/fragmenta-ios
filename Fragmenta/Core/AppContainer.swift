import Foundation

struct AppContainer {
    let config: AppConfig
    let booksService: BooksServiceProtocol
    let searchService: SearchServiceProtocol
    let highlightService: HighlightServiceProtocol

    static func live() -> AppContainer {
        let config = AppConfig.live()
        let apiClient = APIClient(config: config, headersProvider: PublicRequestHeadersProvider())

        return AppContainer(
            config: config,
            booksService: BooksService(apiClient: apiClient),
            searchService: SearchService(apiClient: apiClient),
            highlightService: HighlightService(apiClient: apiClient)
        )
    }
}
